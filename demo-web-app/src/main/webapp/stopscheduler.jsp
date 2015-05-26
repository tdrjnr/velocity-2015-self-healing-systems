<%@ page import="com.velocityconf.selfhealingsystems.demowebapp.*" %>

<%
UploadScheduler uploader = (UploadScheduler)application.getAttribute("uploadScheduler");
uploader.stop();
%>

<html>
  <body>Upload scheduler has been shut down.</body>
</html>
