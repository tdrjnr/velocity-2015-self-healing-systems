package com.velocityconf.selfhealingsystems.demowebapp;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class ContextListener implements ServletContextListener
{
  private Log log = LogFactory.getLog(getClass());

  @Override
  public void contextInitialized(ServletContextEvent event)
  {
    ConcurrentHashMap<String, AtomicInteger> failedAttemptCounts = new ConcurrentHashMap<>();
    event.getServletContext().setAttribute("failedAttemptsMap", failedAttemptCounts);

    log.info("Application initialized.");
  }

  @Override
  public void contextDestroyed(ServletContextEvent event)
  {
  }
}
