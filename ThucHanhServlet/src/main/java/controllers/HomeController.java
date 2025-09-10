package controllers;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import java.io.IOException;


@WebServlet (urlPatterns = {"/manager/home", "/admin/home", "/index"})

public class HomeController extends HttpServlet {
	private static final long serialVersionUID = 1L;
    
    public HomeController() {
        super();
        
    }
	
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String path = request.getServletPath();
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("account") : null;

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        if ("/manager/home".equals(path)) {
            if (user.getRoleid() != 2) {
                response.sendRedirect(request.getContextPath() + "/login");
                return;
            }
            request.getRequestDispatcher("/views/admin/home.jsp").forward(request, response);
        } else if ("/admin/home".equals(path)) {
            if (user.getRoleid() != 1) {
                response.sendRedirect(request.getContextPath() + "/login");
                return;
            }
            request.getRequestDispatcher("/views/admin/home.jsp").forward(request, response);
        } else {
            request.getRequestDispatcher("/views/home.jsp").forward(request, response);
        }
	}

	
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		doGet(request, response);
	}

}