<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <jsp:include page="/common/header.jsp" />
    <title>Trang Chủ - MyWebApp</title>
</head>
<body>
    <jsp:include page="/common/navbar.jsp" />

    <div class="container mt-5">
        <div class="p-5 mb-4 bg-light rounded-3">
            <div class="container-fluid py-5">
                <h1 class="display-5 fw-bold">Chào mừng trở lại!</h1>
                <p class="col-md-8 fs-4">Đây là trang chủ của bạn. Hãy chọn một chức năng bên dưới để bắt đầu.</p>
            </div>
        </div>

        <div class="row text-center">
            <div class="col-md-4 mb-4">
                <div class="card h-100 shadow-sm">
                    <div class="card-body">
                        <div class="card-icon mb-3">
                            <i class="fas fa-user"></i>
                        </div>
                        <h5 class="card-title">Thông tin cá nhân</h5>
                        <p class="card-text">Xem và chỉnh sửa thông tin tài khoản của bạn.</p>
                        <a href="#" class="btn btn-primary">Đi đến</a>
                    </div>
                </div>
            </div>

            <div class="col-md-4 mb-4">
                <div class="card h-100 shadow-sm">
                    <div class="card-body">
                        <div class="card-icon mb-3">
                            <i class="fas fa-history"></i>
                        </div>
                        <h5 class="card-title">Lịch sử mua hàng</h5>
                        <p class="card-text">Kiểm tra các đơn hàng bạn đã đặt trước đây.</p>
                        <a href="#" class="btn btn-primary">Đi đến</a>
                    </div>
                </div>
            </div>

            <c:if test="${sessionScope.account.roleid == 1}">
                <div class="col-md-4 mb-4">
                    <div class="card h-100 shadow-sm border-primary">
                        <div class="card-body">
                            <div class="card-icon mb-3">
                                <i class="fas fa-users-cog"></i>
                            </div>
                            <h5 class="card-title text-primary">Quản lý người dùng</h5>
                            <p class="card-text">Thêm, xóa, sửa tài khoản người dùng trong hệ thống.</p>
                            <a href="${pageContext.request.contextPath}/admin/users" class="btn btn-primary">Đi đến</a>
                        </div>
                    </div>
                </div>
            </c:if>
        </div>
    </div>

    <jsp:include page="/common/footer.jsp" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>