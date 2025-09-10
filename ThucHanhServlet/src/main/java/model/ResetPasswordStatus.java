package model;

public enum ResetPasswordStatus {
    SUCCESS,
    PASSWORD_NOT_MATCH,
    USER_NOT_FOUND,
    EMAIL_MISMATCH,
    PASSWORD_MISMATCH,
    DB_ERROR
}
