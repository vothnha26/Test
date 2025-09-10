package controllers;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import java.io.IOException;
import service.UserService;
import service.impl.UserServiceImpl;
import util.Constant;

@WebServlet(urlPatterns = "/login")
public class LoginController extends HttpServlet {
    private static final long serialVersionUID = 1L;
    public static final String COOKIE_REMEMBER = "username";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("account") != null) {
            response.sendRedirect(request.getContextPath() + "/waiting");
            return;
        }

        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (cookie.getName().equals(COOKIE_REMEMBER)) {
                    String username = cookie.getValue();
                    UserService service = new UserServiceImpl();
                    User user = service.get(username);

                    if (user != null) {
                        session = request.getSession(true);
                        session.setAttribute("account", user);
                        response.sendRedirect(request.getContextPath() + "/waiting");
                        return;
                    }
                }
            }
        }
        
        request.getRequestDispatcher(Constant.Path.LOGIN).forward(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String remember = request.getParameter("remember-me");

        boolean isRememberMe = "on".equals(remember);
        
        String alertMsg = "";
        if (username.isEmpty() || password.isEmpty()) {
            alertMsg = "Tài khoản hoặc mật khẩu không được rỗng";
            request.setAttribute("alert", alertMsg);
            request.getRequestDispatcher(Constant.Path.LOGIN).forward(request, response);
            return;
        }

        UserService service = new UserServiceImpl();
        User user = service.login(username, password);
        
        if (user != null) {
        	Constant.UserId = user.getId();
            HttpSession session = request.getSession(true);
            session.setAttribute("account", user);
            if (isRememberMe) {
                saveRemeberMe(request, response, username);
            }
            response.sendRedirect(request.getContextPath() + "/waiting");
        } else {
            alertMsg = "Tài khoản hoặc mật khẩu không đúng";
            request.setAttribute("alert", alertMsg);
            request.getRequestDispatcher("/views/login.jsp").forward(request, response);
        }
    }

    private void saveRemeberMe(HttpServletRequest request, HttpServletResponse response ,String username) {
    	Cookie cookie = new Cookie(COOKIE_REMEMBER, username);
        cookie.setMaxAge(7 * 24 * 60 * 60);
        cookie.setPath(request.getContextPath());
        response.addCookie(cookie);
    }
}