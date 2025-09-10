package controllers;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(urlPatterns = "/logout")
public class LogoutController extends HttpServlet {
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
	    HttpSession session = req.getSession();
	    session.invalidate();

	    Cookie usernameCookie = new Cookie("username", null); 
	    usernameCookie.setMaxAge(0);
	    usernameCookie.setPath(req.getContextPath());
	    
	    resp.addCookie(usernameCookie);
	    resp.sendRedirect(req.getContextPath() + "/login");
	}
}