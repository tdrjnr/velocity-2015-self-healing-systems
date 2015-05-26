<%@ page import="java.util.concurrent.ConcurrentHashMap" %>
<%@ page import="java.util.concurrent.ConcurrentMap" %>
<%@ page import="java.util.concurrent.atomic.AtomicInteger" %>
<%@ page import="org.apache.commons.logging.Log" %>
<%@ page import="org.apache.commons.logging.LogFactory" %>

<html>

<%
Log log = LogFactory.getLog("login.jsp");

String userName = request.getParameter("userName");
String password = request.getParameter("password");

boolean failedLogin = false;

if (userName != null && password != null)
{
  // TODO:
  // Insert actual authentication code here.
  failedLogin = !password.equals("velocity2015");

  if (failedLogin)
  {
    // This lengthy block of code tracks the number of failed login attempts for each user.
    // Even though it's a demo app, I tried to be a "good citizen" and use proper thread-safety.

    // Get the "tracking map" (see the ContextListener class for initialization).
    ConcurrentMap<String, AtomicInteger> failedAttemptCounts = (ConcurrentMap<String, AtomicInteger>)application.getAttribute("failedAttemptsMap");

    // Get the counter for this user, in a thread-safe manner.
    AtomicInteger count = new AtomicInteger();
    AtomicInteger prev = failedAttemptCounts.putIfAbsent(userName, count);
    if (prev != null)
    {
      count = prev;
    }

    // Increment the counter and get the new value.
    int failedAttempts = count.incrementAndGet();

    log.error("User " + userName + " has failed to log in " + failedAttempts + " time(s).");
  }
  else
  {
    log.info("User " + userName + " has successfully logged in.");
  }
}
else
{
  if (userName == null)
  {
    userName = "";
  }
  if (password == null)
  {
    password = "";
  }
}
%>

  <body>
    <%
    if (failedLogin)
    {
    %>
    <p style="color: red">User name or password is invalid.</p>
    <%
    }
    %>
    <form>
      <table>
        <tr>
          <td>User name:</td>
          <td><input name="userName" value="<%= userName %>" /></td>
        </tr>
        <tr>
          <td>Password:</td>
          <td><input type="password" name="password" value="<%= password %>" /></td>
        </tr>
      </table>
      <input type="submit" />
    </form>
  </body>

</html>
