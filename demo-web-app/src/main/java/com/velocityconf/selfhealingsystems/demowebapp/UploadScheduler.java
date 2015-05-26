package com.velocityconf.selfhealingsystems.demowebapp;

import java.util.concurrent.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class UploadScheduler
{
  private Log log = LogFactory.getLog(getClass());
  private ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);

  public void start(int period)
  {
    log.info("Starting upload task scheduler, with a period of " + period + " seconds.");
    executor.scheduleAtFixedRate(new UploadTask(), period, period, TimeUnit.SECONDS);
  }

  public void stop()
  {
    // Don't log anything, because the whole point of this demo is to simulate something mysteriously stopping with no explanation.
    executor.shutdown();
  }

  private static class UploadTask implements Runnable
  {
    private Log log = LogFactory.getLog(getClass());
    private int counter;

    @Override
    public void run()
    {
      // This is for simulation purposes only.
      String fileName = "foo" + (++counter) + ".log.gz";
      log.info("Successfully uploaded file " + fileName + " to S3.");
    }
  }
}
