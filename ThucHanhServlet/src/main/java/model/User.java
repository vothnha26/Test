package model;

import java.io.Serializable;
import java.sql.Date;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "Users")
@SuppressWarnings("serial") 
public class User implements Serializable 
{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
	private int id;
	
    @Column(unique = true)
	private String email;
	
    @Column(name = "username")
	private String userName;
	
    @Column(name = "fullname")
	private String fullName;
	
    @Column(name = "password")
	private String passWord;
	
    @Column
	private String avatar;
	
    @Column(name = "roleid")
	private int roleid;
	
    @Column
	private String phone;
	
    @Column(name = "created_date")
	private Date createdDate;
	
	public User() {
	    super();
	}
	
	public User(String email, String userName, String fullName, String passWord, String avatar, int roleid,
	        String phone, Date createdDate) {
	    super();
	    this.email = email;
	    this.userName = userName;
	    this.fullName = fullName;
	    this.passWord = passWord;
	    this.avatar = avatar;
	    this.roleid = roleid;
	    this.phone = phone;
	    this.createdDate = createdDate;
	}
	
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public String getEmail() {
		return email;
	}
	public void setEmail(String email) {
		this.email = email;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}
	public String getFullName() {
		return fullName;
	}
	public void setFullName(String fullName) {
		this.fullName = fullName;
	}
	public String getPassWord() {
		return passWord;
	}
	public void setPassWord(String passWord) {
		this.passWord = passWord;
	}
	public String getAvatar() {
		return avatar;
	}
	public void setAvatar(String avatar) {
		this.avatar = avatar;
	}
	public int getRoleid() {
		return roleid;
	}
	public void setRoleid(int roleid) {
		this.roleid = roleid;
	}
	public String getPhone() {
		return phone;
	}
	public void setPhone(String phone) {
		this.phone = phone;
	}
	public Date getCreatedDate() {
		return createdDate;
	}
	public void setCreatedDate(Date createdDate) {
		this.createdDate = createdDate;
	}
	
	public enum ResetPasswordStatus {
	    SUCCESS,
	    USER_NOT_FOUND,
	    EMAIL_MISMATCH,
	    PASSWORD_MISMATCH,
	    DB_ERROR
	}
}
