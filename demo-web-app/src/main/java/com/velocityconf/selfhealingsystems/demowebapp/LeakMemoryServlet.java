package com.velocityconf.selfhealingsystems.demowebapp;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.*;
import javax.servlet.http.*;

public class LeakMemoryServlet extends HttpServlet
{
  private static final List<byte[]> leakedObjects = new ArrayList<>();

  @Override
  public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException
  {
    String blockCountParam = request.getParameter("blockCount");
    String blockSizeParam = request.getParameter("blockSize");
    String delayBetweenBlocksParam = request.getParameter("delayBetweenBlocks");

    // Example usage:
    // http://localhost:8080/shs-demo-app/LeakMemory?blockCount=5&blockSize=1000000000&delayBetweenBlocks=500

    int blockCount = 128;
    int blockSize = 1024;
    int delayBetweenBlocks = 1000;

    if (blockCountParam != null && !blockCountParam.isEmpty())
    {
      blockCount = Integer.parseInt(request.getParameter("blockCount"));
    }
    if (blockSizeParam != null && !blockSizeParam.isEmpty())
    {
      blockSize = Integer.parseInt(request.getParameter("blockSize"));
    }
    if (delayBetweenBlocksParam != null && !delayBetweenBlocksParam.isEmpty()) 
    {
      delayBetweenBlocks = Integer.parseInt(request.getParameter("delayBetweenBlocks"));
    } 

    response.getWriter().println("<html>");
    response.getWriter().println("<head>");
    response.getWriter().println("<link rel='icon' type='image/png' href='velocity_favicon.png'>");
    response.getWriter().println("</head>");
    response.getWriter().println("<body>");

    for (int i = 0; i < blockCount; i++)
    {
      leakedObjects.add(new byte[blockSize]);

      response.getWriter().println("Just leaked " + blockSize + " bytes. " + (blockCount - i - 1) + " block(s) remaining. Will sleep for " + delayBetweenBlocks + " ms...");
      response.getWriter().println("<br />");
      response.getWriter().flush();

      try
      {
        Thread.sleep(delayBetweenBlocks);
      }
      catch (InterruptedException e)
      {
        // For demo purposes, no need to handle this.
      }
    }

    response.getWriter().println("Done!");

    response.getWriter().println("</body>");
    response.getWriter().println("</html>");
    response.getWriter().flush();
  }
}
