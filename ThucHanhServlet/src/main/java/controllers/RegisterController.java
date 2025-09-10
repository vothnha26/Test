package controllers;

import java.io.IOException;
import java.sql.Date;
import java.time.LocalDate;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import model.User;
import service.UserService;
import service.impl.UserServiceImpl;

@WebServlet("/register")
public class RegisterController extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private UserService userService;

	public RegisterController() {
		super();
		this.userService = new UserServiceImpl();
	}

	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		request.getRequestDispatcher("/views/register.jsp").forward(request, response);
	}

	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String fullName = request.getParameter("fullname");
		String username = request.getParameter("username");
		String email = request.getParameter("email");
		String phone = request.getParameter("phone");
		String password = request.getParameter("password");
		String confirmPassword = request.getParameter("confirm-password");

		try {
			// Kiểm tra mật khẩu
			if (!password.equals(confirmPassword)) {
				showError(request, response, "Mật khẩu xác nhận không khớp.");
				return;
			}
			// Kiểm tra tên đăng nhập đã tồn tại chưa
			if (userService.checkExistUsername(username)) {
				showError(request, response, "Tên đăng nhập đã tồn tại.");
				return;
			}
			// Kiểm tra email đã tồn tại chưa
			if (userService.checkExistEmail(email)) {
				showError(request, response, "Email đã được sử dụng.");
				return;
			}
			// Kiểm tra số điện thoại đã tồn tại chưa
			if (userService.checkExistPhone(phone)) {
				showError(request, response, "Số điện thoại đã được sử dụng.");
				return;
			}

			// Sử dụng phương thức register của UserService
			boolean success = userService.register(username, password, email, fullName, phone);

			if (success) {
				response.sendRedirect(request.getContextPath() + "/login?message=register_success");
			} else {
				showError(request, response, "Đăng ký không thành công. Vui lòng thử lại.");
			}
		} catch (Exception e) {
			showError(request, response, "Lỗi hệ thống. Vui lòng thử lại sau.");
		} finally {
			if (userService != null) {
				((UserServiceImpl) userService).close();
			}
		}
	}

	private void showError(HttpServletRequest request, HttpServletResponse response, String message) 
			throws ServletException, IOException {
		request.setAttribute("alert", message);
		request.getRequestDispatcher("/views/register.jsp").forward(request, response);
	}
}