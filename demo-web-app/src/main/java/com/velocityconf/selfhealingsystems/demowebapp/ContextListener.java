package com.velocityconf.selfhealingsystems.demowebapp;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class ContextListener implements ServletContextListener
{
  private Log log = LogFactory.getLog(getClass());
  private UploadScheduler uploadScheduler;

  @Override
  public void contextInitialized(ServletContextEvent event)
  {
    ServletContext context = event.getServletContext();

    // Initialize the "failed login attempts" map, used in login.jsp.
    ConcurrentHashMap<String, AtomicInteger> failedAttemptCounts = new ConcurrentHashMap<>();
    context.setAttribute("failedAttemptsMap", failedAttemptCounts);

    // Start the simulated file uploader.
    int uploadPeriod = Integer.parseInt(context.getInitParameter("uploadPeriod"));
    uploadScheduler = new UploadScheduler();
    uploadScheduler.start(uploadPeriod);

    // Keep a reference to the uploader, so we can simulate stopping it later.
    context.setAttribute("uploadScheduler", uploadScheduler);

    log.info("Application initialized.");
  }

  @Override
  public void contextDestroyed(ServletContextEvent event)
  {
  }
}
