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
  failedLogin = !password.equals("velocity2015");

  if (failedLogin)
  {
    ConcurrentMap<String, AtomicInteger> failedAttemptCounts = (ConcurrentMap<String, AtomicInteger>)session.getAttribute("failedAttemptsMap");

    if (failedAttemptCounts == null)
    {
      failedAttemptCounts = new ConcurrentHashMap<String, AtomicInteger>();
      session.setAttribute("failedAttemptsMap", failedAttemptCounts);
    }

    AtomicInteger count = new AtomicInteger();
    AtomicInteger prev = failedAttemptCounts.putIfAbsent(userName, count);
    if (prev != null)
    {
      count = prev;
    }

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
