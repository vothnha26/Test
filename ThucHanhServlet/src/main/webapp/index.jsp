<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Trang Chủ - MyWebApp</title>

<link
    href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
    rel="stylesheet">

<link rel="stylesheet"
    href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">

<style>
body {
    background-color: #f8f9fa;
}

.card-icon {
    font-size: 3rem;
    color: #0d6efd;
}

.card {
    transition: transform .2s;
}

.card:hover {
    transform: scale(1.05);
}
</style>
</head>
<body>

    <nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
        <div class="container">
            <a class="navbar-brand" href="${pageContext.request.contextPath}/home">
                <i class="fas fa-cubes"></i> MyWebApp
            </a>
            <button class="navbar-toggler" type="button"
                data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <c:choose>
                        <%-- NẾU ĐÃ ĐĂNG NHẬP --%>
                        <c:when test="${not empty sessionScope.account}">
                            <li class="nav-item dropdown"><a
                                class="nav-link dropdown-toggle" href="#" role="button"
                                data-bs-toggle="dropdown"> <i class="fas fa-user-circle"></i>
                                    <strong>${sessionScope.account.fullName}</strong>
                            </a>
                                <ul class="dropdown-menu dropdown-menu-end">
                                    <li><a class="dropdown-item" href="#"> <i
                                            class="fas fa-user-edit me-2"></i> Thông tin cá nhân
                                    </a></li>
                                    <li><a class="dropdown-item" href="#"> <i
                                            class="fas fa-cog me-2"></i> Cài đặt
                                    </a></li>

                                    <%-- KIỂM TRA VAI TRÒ ADMIN --%>
                                    <c:if test="${sessionScope.account.roleid == 1}">
                                        <li><hr class="dropdown-divider"></li>
                                        <li><a class="dropdown-item bg-info text-white"
                                            href="${pageContext.request.contextPath}/admin/home"> <i
                                                class="fas fa-tachometer-alt me-2"></i> Trang Admin
                                        </a></li>
                                    </c:if>

                                    <li><hr class="dropdown-divider"></li>
                                    <li><a class="dropdown-item"
                                        href="${pageContext.request.contextPath}/logout"> <i
                                            class="fas fa-sign-out-alt me-2"></i> Đăng xuất
                                    </a></li>
                                </ul></li>
                        </c:when>

                        <%-- NẾU CHƯA ĐĂNG NHẬP --%>
                        <c:otherwise>
                            <li class="nav-item"><a class="nav-link"
                                href="${pageContext.request.contextPath}/login">Đăng nhập</a></li>
                            <li class="nav-item"><a class="nav-link btn btn-primary text-white"
                                href="${pageContext.request.contextPath}/register">Đăng ký</a></li>
                        </c:otherwise>
                    </c:choose>
                </ul>
            </div>
        </div>
    </nav>

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

            <%-- CHỨC NĂNG CHỈ DÀNH CHO ADMIN --%>
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

    <script
        src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>