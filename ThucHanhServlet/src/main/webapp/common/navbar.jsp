<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
	<div class="container">
		<a class="navbar-brand" href="${pageContext.request.contextPath}/home">
			<i class="fas fa-cubes"></i> MyWebApp
		</a>
		<button class="navbar-toggler" type="button" data-bs-toggle="collapse"
			data-bs-target="#navbarNav">
			<span class="navbar-toggler-icon"></span>
		</button>
		<div class="collapse navbar-collapse" id="navbarNav">
			<ul class="navbar-nav ms-auto">
				<c:choose>
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

					<c:otherwise>
						<li class="nav-item"><a class="nav-link"
							href="${pageContext.request.contextPath}/login">Đăng nhập</a></li>
						<li class="nav-item"><a
							class="nav-link btn btn-primary text-white"
							href="${pageContext.request.contextPath}/register">Đăng ký</a></li>
					</c:otherwise>
				</c:choose>
			</ul>
		</div>
	</div>
</nav>