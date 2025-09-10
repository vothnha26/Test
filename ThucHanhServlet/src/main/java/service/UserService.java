package service;
import model.*;
import model.ResetPasswordStatus;

public interface UserService {
	User login(String username, String password);
	User get(String username);
	ResetPasswordStatus resetPassword(String name, String email, String newPassword, String confirmPassword);
	void insert(User user); 
	boolean register(String email, String password, String username, String fullname, String phone); 
	boolean checkExistEmail(String email); 
	boolean checkExistUsername(String username); 
	boolean checkExistPhone(String phone);
}
