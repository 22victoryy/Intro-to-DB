import java.sql.*;
import java.util.Date;
import java.util.Arrays;
import java.util.List;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   // Can use if you wish: seat letters
   List<String> seatLetters = Arrays.asList("A", "B", "C", "D", "E", "F");

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to 'air_travel, public'.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
      // Implement this method!
      try
      {
	//Properties props = new Properties();
	//props.setProperty("user",username);
	//props.setProperty("password",password);
	//props.setProperty("currentSchema","air_travel, public");
        connection = DriverManager.getConnection(URL, username, password);
	PreparedStatement ps;
        // ResultSet rs;
        String wow = "SET search_path TO air_travel, public";
        ps = connection.prepareStatement(wow);
        ps.execute();
      }
      catch (SQLException e)
      {
        System.err.println("SQL Exception." + e.getMessage());
        return false;
      }
      return true;
   }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
      // Implement this method!
      if (connection != null) {
        try {
        connection.close();
        }
        catch (SQLException e) {
          System.err.println("SQL Exception." + e.getMessage());
          return false;
        }
      }
      return true;
   }
   /* ======================= Airline-related methods ======================= */

   /**
    * Attempts to book a flight for a passenger in a particular seat class. 
    * Does so by inserting a row into the Booking table.
    *
    * Read handout for information on how seats are booked.
    * Returns false if seat can't be booked, or if passenger or flight cannot be found.
    *
    * 
    * @param  passID     id of the passenger
    * @param  flightID   id of the flight
    * @param  seatClass  the class of the seat (economy, business, or first) 
    * @return            true if the booking was successful, false otherwise. 
    */
   public boolean bookSeat(int passID, int flightID, String seatClass) {
      // Implement this method!
      // check passenger exists
      try {
        String finalcountdown = "INSERT INTO Booking " + 
        "VALUES (?, ?,?,current_timestamp,?,?::seat_class,?,?)";
        PreparedStatement fin = connection.prepareStatement(finalcountdown);

        PreparedStatement ps;
        ResultSet rs;
        String passengerExistsQuery = "SELECT count(*) AS count FROM Passenger WHERE id=" + passID;
        ps = connection.prepareStatement(passengerExistsQuery);
        rs = ps.executeQuery();
        rs.next();
        if (rs.getInt("count") == 0){
	        System.err.println("Passenger does not exist");
          return false;
        }
        // check flight exists
        if (!checkFlightExistsAndNotDeparted(flightID)){
          return false;
        }
	      // check empty or waitlist seats
        int countBooked, capacity, bCap, fCap, maxID;
        String IDQuery = "SELECT max(id) as max_id FROM booking";
        ps = connection.prepareStatement(IDQuery);
        rs = ps.executeQuery();
        rs.next();
        maxID = rs.getInt("max_id");

        String bookedCountQuery = "SELECT count(*) as count FROM booking WHERE flight_id="
	                           + flightID + " and seat_class=?::seat_class";
        ps = connection.prepareStatement(bookedCountQuery);
	      ps.setString(1, seatClass);
        rs = ps.executeQuery();
        rs.next();
        countBooked = rs.getInt("count");
	      String airplaneClassCapacityQuery = "SELECT capacity_economy, capacity_business, capacity_first " +
	                      "FROM flight JOIN plane ON flight.plane=plane.tail_number " +
	                      "WHERE flight.id="+ flightID;
	      ps = connection.prepareStatement(airplaneClassCapacityQuery);
        rs = ps.executeQuery();
        rs.next();
	      capacity = rs.getInt("capacity_"+seatClass);
	      if ((seatClass.equals("economy") && (capacity - countBooked) <= -10) || (!seatClass.equals("economy") && (capacity - countBooked) <= 0)){
	        System.err.println("Not enough space");
	        return false;
        }

	      bCap = rs.getInt("capacity_business");
        fCap = rs.getInt("capacity_first");
        fin.setInt(1, maxID + 1);
        fin.setInt(2, passID);
        fin.setInt(3, flightID);
        fin.setString(5, seatClass);

        int[] rc = getSeatLocation(countBooked + 1);
        fin.setString(7,seatLetters.get(rc[1]));
        if (seatClass.equals("first")){
          fin.setInt(6, rc[0]);
        } else if (seatClass.equals("business")){
          fin.setInt(6, rc[0] + (fCap-1)/seatLetters.size() + 1);
        } else {
          if (capacity - countBooked > 0){
            fin.setInt(6, rc[0] + (fCap-1)/seatLetters.size()+(bCap-1)/seatLetters.size()+2);
          } else {
            fin.setNull(6, Types.INTEGER);
            fin.setNull(7, Types.CHAR);
          }
        }

        String priceQuery = "SELECT "+seatClass+" AS price FROM Price WHERE flight_id=" + flightID;
        ps = connection.prepareStatement(priceQuery);
        rs = ps.executeQuery();
        rs.next();
        fin.setInt(4, rs.getInt("price"));
        
        if (fin.executeUpdate() != 1){
          System.err.println("Failed to add booking to relation Booking");
          return false;
        }

      } catch (SQLException se){
        System.err.println("SQL Exception." + se.getMessage());
	se.printStackTrace();
        return false;
      }
      return true;
   }

   /**
    * Attempts to upgrade overbooked economy passengers to business class
    * or first class (in that order until each seat class is filled).
    * Does so by altering the database records for the bookings such that the
    * seat and seat_class are updated if an upgrade can be processed.
    *
    * Upgrades should happen in order of earliest booking timestamp first.
    *
    * If economy passengers left over without a seat (i.e. more than 10 overbooked passengers or not enough higher class seats), 
    * remove their bookings from the database.
    *
    * @param  flightID  The flight to upgrade passengers in.
    * @return           the number of passengers upgraded, or -1 if an error occured.
    */
   public int upgrade(int flightID) {
      // Implement this method!
      try {
        PreparedStatement ps;
        ResultSet rs;

        // check flight exists
        if (!checkFlightExistsAndNotDeparted(flightID)){
          System.out.println("The flight either does not exist or alreadt has been departed");
          return -1;
        }
        else {
          int BusinessBooked, firstBooked;

          String business = "business";
          // ps.setString(1, business);

          String first = "first";
          // ps.setString(1, first);

          String bookedBusinessQuery = "SELECT count(*) as count FROM booking WHERE flight_id="
                              + flightID + " and seat_class='" + business+"'";
          ps = connection.prepareStatement(bookedBusinessQuery);
          rs = ps.executeQuery();
          BusinessBooked= rs.getInt("count");

          String bookedFirstQuery = "SELECT count(*) as count FROM booking WHERE flight_id="
                              + flightID + " and seat_class='" + first+"'";
          ps = connection.prepareStatement(bookedFirstQuery);
          rs = ps.executeQuery();
          firstBooked = rs.getInt("count");


          String BusinessCapacityQuery = "SELECT capacity_"+ business +" AS capacity " +
          "FROM flight JOIN plane ON flight.plane=plane.tail_number " +
          "WHERE flight.id="+ flightID;
          ps = connection.prepareStatement(BusinessCapacityQuery);
          rs = ps.executeQuery();
          rs.first();
          int capacityBusiness = rs.getInt("capacity");


          String FirstCapacityQuery = "SELECT capacity_"+ first+" AS capacity " +
          "FROM flight JOIN plane ON flight.plane=plane.tail_number " +
          "WHERE flight.id="+ flightID;
          ps = connection.prepareStatement(FirstCapacityQuery);
          rs = ps.executeQuery();
          rs.first();
          int capacityFirst = rs.getInt("capacity");

          int numUpgrades = 0;
          // int total_capacity = capacityBusiness + capacityFirst;
          while (rs.next()) {

            int totalBooked = numUpgrades + BusinessBooked + firstBooked;
            int totalCapacity = capacityBusiness + capacityFirst;


            if (totalBooked == totalCapacity) {
              System.out.println("The plane is full.");
              return numUpgrades;
            }

            if (capacityBusiness == BusinessBooked) {
              System.out.println("Business class is full.");

              if (capacityFirst == firstBooked) {
                System.out.println("First class is full. No upgrades available.");
                return numUpgrades;
              }
              else {
                // upgrade to first class, increment counter
                int id = rs.getInt("id");
                int[] rc = getSeatLocation(firstBooked + 1);
                String col = seatLetters.get(rc[1]);
                int row = rc[0];
                String Update = "UPDATE BOOKING SET seat_class='" + business + "',"+
                                " seat_row="+row+" seat_letter='"+col+"' WHERE id=" + id;
                ps = connection.prepareStatement(Update);

                ps.executeUpdate();
                numUpgrades ++;
                firstBooked ++;
              }
            }
            else {
              int id = rs.getInt("id");
              int[] rc = getSeatLocation(firstBooked + 1);
              String col = seatLetters.get(rc[1]);
              int row = rc[0] + (capacityFirst)/seatLetters.size() + 1;
              String Update = "UPDATE BOOKING SET seat_class='" + business + "',"+
                              " seat_row="+row+" seat_letter='"+col+"' WHERE id=" + id;
              ps = connection.prepareStatement(Update);

              ps.executeUpdate();
              // do something
              numUpgrades ++;
              BusinessBooked++;
            }
          }
        }
    }
    catch (SQLException e) {
      System.err.println("SQL Exception." + e.getMessage());
      return -1;
    }
    return -1;
   }
   // fuck this


   /* ----------------------- Helper functions below  ------------------------- */

    // A helpful function for adding a timestamp to new bookings.
    // Example of setting a timestamp in a PreparedStatement:
    // ps.setTimestamp(1, getCurrentTimeStamp());

    /**
    * Returns a SQL Timestamp object of the current time.
    *
    * @return           Timestamp of current time.
    */
   private java.sql.Timestamp getCurrentTimeStamp() {
      java.util.Date now = new java.util.Date();
      return new java.sql.Timestamp(now.getTime());
   }

   // Add more helper functions below if desired.
   private boolean checkFlightExistsAndNotDeparted(int flightID) throws SQLException{
      PreparedStatement ps;
      ResultSet rs;
      String flightExistsQuery = "SELECT count(*) AS count FROM Flight WHERE id=" + flightID;
      ps = connection.prepareStatement(flightExistsQuery);
      rs = ps.executeQuery();
      rs.next();
      if (rs.getInt("count") == 0){
        System.err.println("Flight does not exist");
        return false;
      }
      String flightDepartedQuery = "SELECT count(*) AS count " +
                                  "FROM Departure WHERE flight_id=" + flightID;
      ps = connection.prepareStatement(flightDepartedQuery);
      rs = ps.executeQuery();
      rs.next();
      if (rs.getInt("count") > 0){
        System.err.println("Flight already departed :(");
        return false;
      }
      return true;
   }

   private int[] getSeatLocation(int number){
    int column = (number - 1) % seatLetters.size();
    int row = (number - 1)/seatLetters.size() + 1;
    return new int[] {row, column};
   }

  /* ----------------------- Main method below  ------------------------- */

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      System.out.println("Running the code!");

      try
      {
        Assignment2 a2 = new Assignment2();
        String url = "jdbc:postgresql://localhost:5432/csc343h-"+args[0];
        if (a2.connectDB(url, args[0],"")){
	        a2.bookSeat(Integer.parseInt(args[1]),Integer.parseInt(args[2]),args[3]);
       }
      }
      catch(SQLException e)
      {
        System.err.println("SQL Exception." + e.getMessage());
        return;
      }
   }

}
