package com.velocityconf.selfhealingsystems.demowebapp;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.*;
import javax.servlet.http.*;

import org.apache.commons.logging.*;

public class LogErrorsServlet extends HttpServlet
{
  private static final Log log = LogFactory.getLog(LogErrorsServlet.class);

  @Override
  public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException
  {
    log.error("Here's an error!");
  }
}
