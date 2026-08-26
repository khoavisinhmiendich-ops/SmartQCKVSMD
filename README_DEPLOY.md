# SMART QC — Supabase + Vercel + PWA (bản triển khai)

## Mục tiêu
- Giữ nguyên giao diện/chức năng SMART QC hiện tại.
- Dữ liệu QC được lưu trong Supabase PostgreSQL thay vì chỉ ở từng máy.
- Các máy tính/điện thoại cùng Workspace nhìn thấy dữ liệu chung và nhận cập nhật Realtime.
- Website chạy trên Vercel HTTPS.
- Có PWA: Android/Chrome/Edge có thể cài thành ứng dụng có icon; iPhone/iPad dùng Safari → Chia sẻ → Thêm vào Màn hình chính.

## A. Tạo Supabase
1. Vào https://supabase.com/ → New project.
2. Chọn region gần Việt Nam, ví dụ Singapore.
3. Mở SQL Editor → chạy toàn bộ `SUPABASE_SETUP.sql`.
4. Vào Authentication → Users → tạo tài khoản cho từng nhân viên.
5. Sao chép UUID của từng user.
6. Trong SQL Editor, thêm thành viên vào workspace:

```sql
insert into public.smartqc_workspace_members (workspace_id, user_id, role)
values ('smartqc-qyh-shared', 'UUID_NGUOI_DUNG', 'admin');
```

Dùng `staff` cho người nhập/sửa QC và `viewer` cho người chỉ xem.

## B. Lấy khóa đúng
Vào Project Settings → API.
- `SUPABASE_URL`: Project URL.
- `SUPABASE_PUBLISHABLE_KEY`: Publishable key (hoặc anon key ở project cũ).

KHÔNG dùng `service_role` hoặc secret key trong trình duyệt.

## C. Đưa source lên GitHub
Giữ nguyên cấu trúc thư mục:

```text
index.html
config.js
manifest.webmanifest
sw.js
vercel.json
package.json
scripts/build-config.mjs
icons/
SUPABASE_SETUP.sql
README_DEPLOY.md
```

Tạo repository GitHub, ví dụ `smart-qc` rồi upload toàn bộ thư mục.

## D. Kết nối GitHub → Vercel
1. Vào https://vercel.com/ → Add New Project.
2. Import repository GitHub `smart-qc`.
3. Framework Preset: Other / không framework.
4. Build Command: `npm run build`.
5. Output Directory: `.` (thư mục gốc).
6. Deploy.

## E. Khai báo Environment Variables trên Vercel
Vào Vercel → Project → Settings → Environment Variables.

Thêm:

```text
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxx
SMART_QC_WORKSPACE=smartqc-qyh-shared
```

Chọn Production (và Preview nếu cần), Save rồi Redeploy. Build script sẽ tạo `config.js` tự động. Publishable key có thể xuất hiện trong frontend; RLS mới là lớp bảo vệ dữ liệu. Tuyệt đối không đưa service_role/secret key vào đây.

## F. Lần đầu trên thiết bị đầu tiên
1. Mở URL Vercel.
2. Đăng nhập SMART QC theo giao diện hiện tại.
3. Vào `Hệ thống → Dữ liệu → Đồng bộ Supabase → Thiết lập`.
4. Chọn `Đăng nhập cloud` và dùng tài khoản Supabase đã được thêm vào `smartqc_workspace_members`.
5. Nếu Workspace chưa có dữ liệu, thiết bị đầu tiên sẽ đẩy dữ liệu SMART QC hiện có lên cloud.

## G. Thiết bị thứ 2, 3, điện thoại...
1. Mở cùng URL Vercel.
2. Đăng nhập SMART QC.
3. Đăng nhập cloud bằng tài khoản Supabase được cấp.
4. Dữ liệu trong Workspace sẽ được tải xuống.
5. Khi một thiết bị lưu QC, các thiết bị khác đã mở app sẽ nhận thay đổi qua Supabase Realtime.

## H. Cài như ứng dụng
- Android/Chrome/Edge: dùng nút cài ứng dụng trên giao diện hoặc menu trình duyệt → Install app.
- iPhone/iPad: Safari → Chia sẻ → Thêm vào Màn hình chính.
- Windows/macOS: Chrome/Edge → Install SMART QC.

PWA dùng `manifest.webmanifest`, icon 192/512 và service worker. Không cần đóng gói APK chỉ để cài như ứng dụng web.

## I. Lưu ý quan trọng về dữ liệu
- Supabase lưu dữ liệu ở PostgreSQL, không phụ thuộc localStorage của một máy.
- Bản hiện tại dùng một dòng JSON `smartqc_shared_state` để chuyển đổi nhanh từ app cũ sang cloud, giữ nguyên giao diện và logic.
- Đây là mô hình migration tiện lợi. Nếu sau này có nhiều người dùng đồng thời hoặc cần hồ sơ bệnh nhân, nên chuyển sang các bảng chuẩn hóa riêng (QC results, tests, machines, lots, audit logs) và chính sách RLS chi tiết hơn.
- Không coi localStorage là bản lưu chính; cloud mới là nguồn dữ liệu dùng chung khi đã đăng nhập cloud.

## J. Nếu sửa Environment Variables
Vercel chỉ áp dụng Environment Variables cho deployment mới. Sau khi thay đổi URL/key/workspace, hãy Redeploy.
