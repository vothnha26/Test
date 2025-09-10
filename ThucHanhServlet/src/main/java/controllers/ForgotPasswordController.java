package controllers;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import util.Constant;
import model.ResetPasswordStatus;
import service.UserService;
import service.impl.UserServiceImpl;

/**
 * Servlet implementation class ForgetPassController
 */
@WebServlet("/reset-password-simple")
public class ForgotPasswordController extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public ForgotPasswordController() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		request.getRequestDispatcher(Constant.Path.FORGOT_PASS).forward(request, response);
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		UserService userService = new UserServiceImpl();
		
		String username = request.getParameter("username");
		String email = request.getParameter("email");
		String newPassword = request.getParameter("newPassword");
		String confirmPassword = request.getParameter("confirmPassword");
		System.out.println(username);
		ResetPasswordStatus status = userService.resetPassword(username, email, newPassword, confirmPassword);

		if (status == ResetPasswordStatus.SUCCESS) {
		    response.sendRedirect(request.getContextPath() + "/login?message=reset_success");
		} else {
		    String errorMessage = "Lỗi không xác định";
		    if (status == ResetPasswordStatus.USER_NOT_FOUND) {
		        errorMessage = "Tài khoản không tồn tại!";
		    } else if (status == ResetPasswordStatus.EMAIL_MISMATCH) {
		        errorMessage = "Email không khớp với tài khoản!";
		    } else if (status == ResetPasswordStatus.PASSWORD_MISMATCH || status == ResetPasswordStatus.PASSWORD_NOT_MATCH) {
		        errorMessage = "Mật khẩu xác nhận không khớp!";
		    } else if (status == ResetPasswordStatus.DB_ERROR) {
		        errorMessage = "Lỗi hệ thống, vui lòng thử lại!";
		    }
		    
		    request.setAttribute("error", errorMessage);
		    request.getRequestDispatcher("/views/reset-password-simple.jsp").forward(request, response);
		}
	}

}
