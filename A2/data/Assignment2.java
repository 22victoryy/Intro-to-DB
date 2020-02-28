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
        ResultSet rs;
        String wow = "SET search_path TO air_travel, public";
        ps = connection.prepareStatement(wow);
        ps.execute();
	
      }
      catch (SQLException e)
      {
        System.err.println("SQL Exception." + e.getMessage());
        return true ;
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
      try
      {
        connection.close();
      }
      catch (SQLException e)
      {
        System.err.println("SQL Exception." + e.getMessage());
        return false;
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
        String flightExistsQuery = "SELECT count(*) AS count FROM Flight WHERE flight_num=" + flightID;
        ps = connection.prepareStatement(flightExistsQuery);
        rs = ps.executeQuery();
        rs.next();
        if (rs.getInt("count") == 0){
	    System.err.println("Flight does not exist");
            return false;
        }
	// check empty or waitlist seats
	int countBooked, capacity;
        String bookedCountQuery = "SELECT count(*) as count FROM booking WHERE flight_id="
	                           + flightID + " and seat_class=?::seat_class";
        ps = connection.prepareStatement(bookedCountQuery);
	ps.setString(1, seatClass);
        rs = ps.executeQuery();
        rs.next();
        countBooked = rs.getInt("count");
	String airplaneClassCapacityQuery = "SELECT capacity_"+seatClass+" AS capacity " +
	                      "FROM flight JOIN plane ON flight.plane=plane.tail_number " +
	                      "WHERE flight.id="+ flightID;
	ps = connection.prepareStatement(airplaneClassCapacityQuery);
        rs = ps.executeQuery();
        rs.next();
	capacity = rs.getInt("capacity");
	if ((seatClass == "economy" && capacity - countBooked < -10) || capacity - countBooked <= 0){
	    System.err.println("Not enough space");
	    return false;
	}
      } catch (SQLException se){
        System.err.println("SQL Exception." + se.getMessage());
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
      try 
      {
        PreparedStatement ps;
        ResultSet rs;
        String allFlights = "select * from flight where flightID =" + flightID;
        java.sql.Timestamp time = getCurrentTimeStamp();
                
  
        ps = connection.prepareStatement(allFlights);
  
        rs = ps.executeQuery();
        
        // first check if the flight exists
        // check waitlist/empty seats
        // check if the row is full --> if the row is full, upgrade it 
        // 
        
        if (rs.getInt("count") == 0){
            return -1;
        }
        
        // check if the row is full
        String allSeats = "select * from plane where flightID =" + flightID;
        
        ps = connection.prepareStatement(allSeats);
        rs = ps.executeQuery();
        
      
      }
      catch (SQLException e)
      {
        System.err.println("SQL Exception." + e.getMessage());
      }
      // if empty seat, return 1 
      return -1;
   }


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


  
  /* ----------------------- Main method below  ------------------------- */

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      System.out.println("Running the code!");

      try
      {
        Assignment2 a2 = new Assignment2();
        String url = "jdbc:postgresql://localhost:5432/csc343h-"+args[0];
        if (a2.connectDB(url, args[0],"")){
	    a2.bookSeat(7,1,"economy");
	    a2.bookSeat(1,11,"economy");
	    
       }
      }
      catch(SQLException e)
      {
        System.err.println("SQL Exception." + e.getMessage());
        return;
      }
      
   }

}
