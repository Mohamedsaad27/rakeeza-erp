# Project Development Plan - Phase 1: Authentication & Authorization
----------------------------------------------------------------------------------------------------------------------

## Project Overview
- **Project Type**: Multi-tenant ERP System (API only)
- **Laravel Version**: 13
- **Architecture**: Custom Clean Architecture (Module-based)
- **Database**: Single Database with Multi-tenancy via tenant_id
- **First Phase Focus**: Authentication, Roles & Permissions System
- **Key Requirement**: Super Admin can assign any role and permissions

----------------------------------------------------------------------------------------------------------------------

## Our ERP systems Will include:
- **Finance & Accounting**
- **Inventory Management**
- **Sales & CRM**
- **Purchasing**
- **HR & Payroll**
- **Reporting & Analytics**
----------------------------------------------------------------------------------------------------------------------


## Packages Will Use In Backend 
 - Laravel Passport [For Authentication ]
 - spatie/laravel-permission 
 - laravel-cashier (billing SaaS)
 - Spatie Laravel Activitylog [For Activity Log ]
 - Laravel Horizon [Handle heavy ERP operations: reports - emails - imports]
 - Laravel Notifications [Emails - SMS - In-app notifications ] 
 - spatie/laravel-multitenancy [Manage Multi Tenancy]
 - maatwebsite/excel [Excel export/import]

----------------------------------------------------------------------------------------------------------------------


🟡 Phase 1 (Core ERP)
- Auth + RBAC
- Tenancy system
- CRM (customers/suppliers)
- Products + categories
- Basic sales/purchase
- Inventory (stock movements)
----------------------------------------------------------------------------------------------------------------------

🟡 Phase 2 (Business Logic)
- Accounting (journal system)
- Payments & invoices
- Expense management
- Reports (basic)
----------------------------------------------------------------------------------------------------------------------

🟡 Phase 3 (Advanced ERP)
- HR & payroll
- CRM pipelines
- Advanced reports
- Notifications system
----------------------------------------------------------------------------------------------------------------------

🟡 Phase 4 (SaaS)
- Subscription plans
- Tenant onboarding
- Usage limits
- Billing


----------------------------------------------------------------------------------------------------------------------


## Directory Structure

```
App/
├── Modules/
│   ├── Auth/
│   │   ├── Application/
│   │   │   ├── DTOs/
│   │   │   ├── Exceptions/
│   │   │   └── UseCases/
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   ├── Enums/
│   │   │   ├── Interfaces/
│   │   │   └── Services/
│   │   ├── Infrastructure/
│   │   │   ├── Persistence/
│   │   │   ├── Providers/
│   │   │   ├── Config/
│   │   │   ├── Database/
│   │   │   └── ExternalServices/
│   │   └── Presentation/
│   │       ├── Http/
│   │       ├── Routes/
│   │       └── Resources/
│   ├── Roles/
│   │   └── [Similar structure as Auth module]
│   └── Permissions/
│       └── [Similar structure as Auth module]
├── Global/
│   ├── Operations/
│   │   ├── DTOs/
│   │   ├── Exceptions/
│   │   └── UseCases/
│   ├── Helpers/
│   │   ├── Response/
│   │   └── [Other helpers]
│   └── Shared/
│       ├── Entities/
│       ├── Enums/
│       └── Interfaces/
└── Http/
    ├── Controllers/
    ├── Middleware/
    └── Kernel.php
```
----------------------------------------------------------------------------------------------------------------------

## Database Schema Design

### Core Tables
```sql
-- Tenants Table
CREATE TABLE tenants (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Users Table (Multi-tenant)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NOT NULL,
    avatar VARCHAR(255) NULL,
    status ENUM('active', 'inactive', 'pending') DEFAULT 'pending',
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    UNIQUE KEY (tenant_id, email)
);

-- Roles Table
CREATE TABLE roles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_system ENUM('yes', 'no') DEFAULT 'no',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    UNIQUE KEY (tenant_id, name)
);

-- Permissions Table
CREATE TABLE permissions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    UNIQUE KEY (tenant_id, name)
);

-- Role-User Pivot Table
CREATE TABLE role_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assigned_by BIGINT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id),
    UNIQUE KEY (tenant_id, user_id, role_id)
);

-- Permission-Role Pivot Table
CREATE TABLE permission_role (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE KEY (tenant_id, role_id, permission_id)
);

-- Permission-User Pivot Table (for direct user permissions)
CREATE TABLE permission_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    assigned_by BIGINT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id),
    UNIQUE KEY (tenant_id, user_id, permission_id)
);

-- Audit Logs Table
CREATE TABLE audit_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id BIGINT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    url VARCHAR(255) NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```
----------------------------------------------------------------------------------------------------------------------

## Module Structure Implementation

### 1. Auth Module
```
App/Modules/Auth/
├── Application/
│   ├── DTOs/
│   │   ├── LoginDTO.php
│   │   ├── RegisterDTO.php
│   │   ├── ForgotPasswordDTO.php
│   │   └── ResetPasswordDTO.php
│   ├── Exceptions/
│   │   ├── AuthenticationFailedException.php
│   │   ├── UserNotFoundException.php
│   │   └── InvalidCredentialsException.php
│   └── UseCases/
│       ├── LoginUser.php
│       ├── RegisterUser.php
│       ├── ForgotPassword.php
│       ├── ResetPassword.php
│       └── LogoutUser.php
├── Domain/
│   ├── Entities/
│   │   ├── User.php
│   │   └── Tenant.php
│   ├── Enums/
│   │   ├── UserStatusEnum.php
│   │   └── TenantStatusEnum.php
│   ├── Interfaces/
│   │   ├── AuthRepositoryInterface.php
│   │   └── UserInterface.php
│   └── Services/
│       ├── AuthService.php
│       └── PasswordResetService.php
├── Infrastructure/
│   ├── Persistence/
│   │   ├── Models/
│   │   │   ├── User.php
│   │   │   └── Tenant.php
│   │   └── Repositories/
│       │   ├── AuthRepository.php
│       │   └── UserRepository.php
│   ├── Providers/
│   │   ├── AuthServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   └── AuthModuleServiceProvider.php
│   ├── Config/
│   │   └── config.php
│   ├── Database/
│   │   ├── Migrations/
│   │   ├── Factories/
│   │   └── Seeders/
│   └── ExternalServices/
│       └── EmailService.php
└── Presentation/
    ├── Http/
    │   ├── Controllers/
    │   │   ├── AuthController.php
    │   │   ├── UserController.php
    │   │   └── PasswordResetController.php
    │   ├── Requests/
    │   │   ├── LoginRequest.php
    │   │   ├── RegisterRequest.php
    │   │   └── ForgotPasswordRequest.php
    │   └── Resources/
    │       ├── UserResource.php
    │       └── AuthResource.php
    ├── Routes/
    │   └── api.php
    └── Resources/Lang/
        ├── en/auth.php
        └── ar/auth.php
```
----------------------------------------------------------------------------------------------------------------------

### 2. Roles Module
```
App/Modules/Roles/
├── Application/
│   ├── DTOs/
│   │   ├── CreateRoleDTO.php
│   │   ├── UpdateRoleDTO.php
│   │   └── AssignPermissionDTO.php
│   ├── Exceptions/
│   │   ├── RoleNotFoundException.php
│   │   └── PermissionNotFoundException.php
│   └── UseCases/
│       ├── CreateRole.php
│       ├── UpdateRole.php
│       ├── DeleteRole.php
│       ├── AssignPermissions.php
│       └── RemovePermissions.php
├── Domain/
│   ├── Entities/
│   │   ├── Role.php
│   │   └── Permission.php
│   ├── Enums/
│   │   └── RoleStatusEnum.php
│   ├── Interfaces/
│   │   ├── RoleRepositoryInterface.php
│   │   └── PermissionRepositoryInterface.php
│   └── Services/
│       └── RolePermissionService.php
├── Infrastructure/
│   ├── Persistence/
│   │   ├── Models/
│   │   │   ├── Role.php
│   │   │   └── Permission.php
│   │   └── Repositories/
│       │   ├── RoleRepository.php
│       │   └── PermissionRepository.php
│   ├── Providers/
│   │   ├── RolesServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   └── RolesModuleServiceProvider.php
│   └── [Similar structure as Auth module]
└── Presentation/
    ├── Http/
    │   ├── Controllers/
    │   │   ├── RoleController.php
    │   │   └── PermissionController.php
    │   └── [Similar structure as Auth module]
    └── [Similar structure as Auth module]
```
----------------------------------------------------------------------------------------------------------------------

## Phase 1 Implementation Tasks

### Task 1: Setup & Configuration
- [ ] Configure Laravel 13 with latest dependencies
- [ ] Set up environment variables and .env file
- [ ] Configure JWT/Tokens for authentication
- [ ] Set up basic CORS and security headers
- [ ] Configure mail for email verification and password reset
----------------------------------------------------------------------------------------------------------------------

### Task 2: Database Migration & Models
- [ ] Create  database migrations Per Module each module has her Migrations only 
- [ ] Implement User model with tenant_id and tenant relationship
- [ ] Create Tenant model
- [ ] Implement Role and Permission models with tenant_id
- [ ] Create pivot tables for relationships
- [ ] Create Audit Log model
- [ ] Set up model factories and seeders
----------------------------------------------------------------------------------------------------------------------

### Task 3: Authentication Module (4 days)
- [ ] Implement LoginUser use case
- [ ] Implement RegisterUser use case
- [ ] Create JWT token generation service
- [ ] Implement password hashing and verification
- [ ] Create AuthController with all endpoints
- [ ] Implement authentication middleware
- [ ] Implement email verification system
- [ ] Create password reset functionality with email
- [ ] Create authentication validation rules
----------------------------------------------------------------------------------------------------------------------

### Task 4: Roles & Permissions Module (3 days)
- [ ] Implement CreateRole use case
- [ ] Implement UpdateRole use case
- [ ] Create Role and Permission controllers
- [ ] Implement permission assignment system
- [ ] Create role-based authorization middleware
- [ ] Implement permission checking service
- [ ] Set up seeder for default roles and permissions

### Task 5: API Development (2 days)
- [ ] Create API authentication endpoints
- [ ] Build user management API endpoints
- [ ] Implement role management API endpoints
- [ ] Create permission management API endpoints
- [ ] Add API documentation
- [ ] Implement API rate limiting
----------------------------------------------------------------------------------------------------------------------

### Task 6: Testing & Quality Assurance (2 days)
- [ ] Write unit tests for all use cases
- [ ] Create integration tests for authentication
- [ ] Test multi-tenancy isolation
- [ ] Implement security testing
- [ ] Performance testing for API endpoints
- [ ] Code review and optimization
----------------------------------------------------------------------------------------------------------------------

### Task 7: Documentation (1 day)
- [ ] Create API documentation
- [ ] Write setup and configuration guide
- [ ] Document multi-tenancy implementation
- [ ] Create user manual for admin interface
- [ ] Add code comments and documentation
----------------------------------------------------------------------------------------------------------------------

## API Endpoints

### Authentication Endpoints
```
POST /api/auth/login
POST /api/auth/register
POST /api/auth/logout
POST /api/auth/refresh
POST /api/auth/forgot-password
POST /api/auth/reset-password
POST /api/auth/verify-email
```
----------------------------------------------------------------------------------------------------------------------

### User Management Endpoints
```
GET /api/users
POST /api/users
GET /api/users/{id}
PUT /api/users/{id}
DELETE /api/users/{id}
PUT /api/users/{id}/status
```
----------------------------------------------------------------------------------------------------------------------

### Role Management Endpoints
```
GET /api/roles
POST /api/roles
GET /api/roles/{id}
PUT /api/roles/{id}
DELETE /api/roles/{id}
GET /api/permissions
POST /api/permissions
PUT /api/roles/{roleId}/permissions
DELETE /api/roles/{roleId}/permissions
```
----------------------------------------------------------------------------------------------------------------------

## Security Implementation

### Authentication Security
- JWT tokens with expiration and refresh mechanism
- Password hashing using bcrypt
- Rate limiting for authentication endpoints
- Secure session management
- Multi-factor authentication readiness
----------------------------------------------------------------------------------------------------------------------

### Authorization Security
- Role-based access control (RBAC)
- Permission-based access control (PBAC)
- Attribute-based access control (ABAC) readiness
- Super admin override capability
- Audit logging for all permission changes
----------------------------------------------------------------------------------------------------------------------

### Multi-tenancy Security
- Row-level security implementation
- Tenant context middleware
- Data encryption for sensitive information
- Regular security audits
----------------------------------------------------------------------------------------------------------------------

## Default Roles and Permissions

### Default Roles
1. **Super Admin** (System role)
   - Can access all modules and features
   - Can assign any role to any user
   - Can create, update, delete any role or permission
   - Cannot be assigned or removed by other users

2. **Admin**
   - Can manage users within their tenant
   - Can create and manage roles
   - Can assign permissions to roles
   - Cannot modify system roles

3. **Manager**
   - Can view and manage team members
   - Can assign basic permissions
   - Cannot create or delete roles

4. **User**
   - Basic access to assigned features
   - Cannot manage other users
   - Limited permissions based on assigned roles
----------------------------------------------------------------------------------------------------------------------

### Default Permissions
- `users.view` - View user list
- `users.create` - Create new users
- `users.update` - Update user information
- `users.delete` - Delete users
- `users.status` - Change user status
- `roles.view` - View roles
- `roles.create` - Create new roles
- `roles.update` - Update roles
- `roles.delete` - Delete roles
- `permissions.assign` - Assign permissions to roles
- `permissions.view` - View permissions
- `dashboard.view` - View admin dashboard
- `audit.logs.view` - View audit logs
----------------------------------------------------------------------------------------------------------------------

## Performance Considerations

### Database Optimization
- Database indexing for frequently queried columns
- Query optimization for multi-tenant data
- Caching of user roles and permissions
- Connection pooling for database connections

### API Performance
- Response caching for static data
- Pagination for large datasets
- Efficient database queries
- API response optimization

----------------------------------------------------------------------------------------------------------------------

## Success Criteria

### Functional Requirements
- [ ] Multi-tenant user authentication system
- [ ] Role-based access control implementation
- [ ] Permission management system
- [ ] Super admin can assign any role and permissions
- [ ] Audit logging for all security-related actions
- [ ] Email verification and password reset functionality

### Non-Functional Requirements
- [ ] Response time < 200ms for API endpoints
- [ ] 99.9% uptime for authentication service
- [ ] Secure data isolation between tenants
- [ ] Scalable architecture for future modules
- [ ] Comprehensive test coverage > 80%

### Security Requirements
- [ ] No SQL injection vulnerabilities
- [ ] Protection against XSS attacks
- [ ] CSRF protection for web interfaces
- [ ] Authentication token security
- [ ] Regular security audit capabilities
----------------------------------------------------------------------------------------------------------------------

## Next Phases

### Phase 2: Core Business Modules
- User Profile Management
- System Configuration
- Basic Reporting
- Notification System
----------------------------------------------------------------------------------------------------------------------

### Phase 3: Advanced Features
- Advanced Analytics
- Integration Management
- Advanced Security Features
- Mobile API Development
----------------------------------------------------------------------------------------------------------------------

### Phase 4: Optimization & Scaling
- Performance optimization
- Database optimization
- Infrastructure scaling
----------------------------------------------------------------------------------------------------------------------
