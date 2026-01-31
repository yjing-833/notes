#!/bin/bash
set -euo pipefail

# Hàm thông báo lỗi và thoát
error_exit() {
    echo "Lỗi: $1" >&2
    exit 1
}

# Cập nhật danh sách gói và cài đặt các gói cần thiết
update_and_install() {
    echo "Đang cập nhật danh sách gói..."
    sudo apt update || error_exit "Cập nhật danh sách gói thất bại."
    sudo apt install -y qemu-kvm unzip cpulimit python3-pip wget || error_exit "Cài đặt các gói cần thiết thất bại."
}

# Kiểm tra và mount phân vùng vào /mnt nếu cần
mount_partition() {
    echo "Kiểm tra phân vùng đã được mount vào /mnt..."
    if mount | grep -q "on /mnt "; then
        echo "Phân vùng đã được mount vào /mnt. Tiếp tục..."
    else
        echo "Phân vùng chưa được mount. Đang tìm phân vùng lớn hơn 500GB..."
        partition=$(lsblk -b --output NAME,SIZE,MOUNTPOINT | awk '$2 > 500000000000 && $3 == "" {print $1}' | head -n 1)
        if [ -n "$partition" ]; then
            echo "Đã tìm thấy phân vùng: /dev/$partition"
            sudo mount "/dev/${partition}1" /mnt || error_exit "Mount phân vùng /dev/${partition}1 thất bại."
            echo "Phân vùng /dev/${partition}1 đã được mount vào /mnt."
        else
            error_exit "Không tìm thấy phân vùng có dung lượng lớn hơn 500GB chưa được mount."
        fi
    fi
}

# Hiển thị menu lựa chọn hệ điều hành và thiết lập biến file_url
select_os() {
    echo "Chọn hệ điều hành để chạy VM (các hđh sẽ được cập nhật trong tương lai):"
    echo "1. Windows 11 23H2 (22631.2861) bản gốc chính chủ M$"
    echo "2. Ubuntu 22.04 LTS (có quyền SSH, cài Tài Scale để chạy SSH và mật khẩu là 1; username runner)"
    echo "3. Windows 11 24H2 gốc"
    echo "4. UEFI 4 Windows OS (Windows 11 23H2; Windows 10 22H2; Windows 8.1; Windows 7)"
    echo "5. Tùy chọn tải file OS qcow2 từ URL (nhập URL tùy ý)"
    read -rp "Nhập lựa chọn của bạn: " user_choice

    case "$user_choice" in
        1)
            echo "Bạn đã chọn Windows 11 23H2 (22631.2861)."
            file_url="https://api.cloud.hashicorp.com/vagrant-archivist/v1/object/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiIyMWZlYWNmYi0xMWY5LTRkMTEtOGM2OC0xMTQ5YmY1NmY2YzIiLCJtb2RlIjoiciIsImZpbGVuYW1lIjoid2luMTFtb2RyZHB3Zl8xLjBfcWVtdV9hbWQ2NC5ib3gifQ.WYMn2onERXAiIk9BHyZtMJZZirZS6H9tzJAC5Sj8KIA"
            ;;
        2)
            echo "Bạn đã chọn Ubuntu 22.04 LTS."
            file_url="https://api.cloud.hashicorp.com/vagrant-archivist/v1/object/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiI1ZGQ1NmM1OC04ZDQ4LTQ0NzgtOWE1Zi0wYjNmYzgyYzRiNTkiLCJtb2RlIjoiciIsImZpbGVuYW1lIjoidWJ1bnR1c2VydmVyMjJfMC4wX3FlbXVfYW1kNjQuYm94In0.tYprxQPqKwTPaqlfna0u7rIlpD3WYbK03haABvT3KQk"
            ;;
        3)
            echo "Bạn đã chọn Windows 11 24H2 gốc."
            file_url="https://api.cloud.hashicorp.com/vagrant-archivist/v1/object/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJsaW51eHVzZXJzZmFrZS9XaW5kb3dzMTEyNEgyLzI0LjIvV2luMTEyNEgyL2QyOTQwOWVhLWFjY2MtMTFlZi05NGM4LTVhOGNhNzBiNzRhNSIsIm1vZGUiOiJyIiwiZmlsZW5hbWUiOiJXaW5kb3dzMTEyNEgyXzI0LjJfV2luMTEyNEgyX2FtZDY0LmJveCJ9.7DD39XJxF8PjIdhHcuEABTPiZbPgq_CEgVHrV9ka_eg"
            ;;
        4)
            echo "Bạn đã chọn UEFI 4 Windows OS."
            file_url="https://www.dropbox.com/scl/fi/cm4kqg5f5iis40bzmy7yo/windualboot.qcow2?rlkey=0aybiajbpqve86lpjvu5ah9x2&dl=1"
            ;;
        5)
            echo "Bạn đã chọn tùy chọn tải file OS qcow2 từ URL."
            read -rp "Nhập URL: " file_url
            ;;
        *)
            error_exit "Lựa chọn không hợp lệ. Vui lòng chạy lại script và chọn từ 1 đến 5."
            ;;
    esac
    file_name="/mnt/a.qcow2"
}

# Hỏi người dùng có bật âm thanh không và thiết lập flag AUDIO_ENABLED
ask_audio() {
    read -rp "Bạn có muốn kích hoạt âm thanh không? (y/n): " audio_choice
    case "$audio_choice" in
        [Yy]* )
            AUDIO_ENABLED=1
            echo "CẢNH BÁO: VUI LÒNG CÀI SẴN TAILSCALE VÀ VIRT-VIEWER TRÊN MÁY ĐỂ CÓ THỂ NGHE NHẠC TRÊN VNC."
            echo "Chờ 5 giây để tiếp tục..."
            sleep 5
            ;;
        * )
            AUDIO_ENABLED=0
            ;;
    esac
}

# Tải file Qcow2
download_file() {
    echo "Đang tải file $file_name từ $file_url..."
    wget -O "$file_name" "$file_url" || error_exit "Tải file thất bại. Kiểm tra kết nối mạng hoặc URL."
}

# Khởi chạy máy ảo với KVM (có hoặc không có hỗ trợ âm thanh)
start_vm() {
    echo "Đang khởi chạy máy ảo..."
    if [ "$AUDIO_ENABLED" -eq 1 ]; then
        SPICE_PORT=5924
        sudo cpulimit -l 80 -- sudo kvm \
            -daemonize \
            -cpu host,+topoext,hv_relaxed,hv_spinlocks=0x1fff,hv-passthrough,+pae,+nx,kvm=on,+svm \
            -smp 2,cores=2 \
            -M q35,usb=on \
            -device usb-tablet \
            -m 4G \
            -device virtio-balloon-pci \
            -vga virtio \
            -net nic,netdev=n0,model=virtio-net-pci \
            -netdev user,id=n0,hostfwd=tcp::3389-:3389 \
            -boot c \
            -device virtio-serial-pci \
            -device virtio-rng-pci \
            -enable-kvm \
            -drive file="$file_name" \
            -drive if=pflash,format=raw,readonly=off,file=/usr/share/ovmf/OVMF.fd \
            -uuid e47ddb84-fb4d-46f9-b531-14bb15156336 \
            -soundhw hda \
            -chardev spicevmc,id=vdagent,name=vdagent \
            -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
            -spice port=${SPICE_PORT},disable-ticketing
        echo "Máy ảo đã khởi động với hỗ trợ âm thanh."
    else
        sudo cpulimit -l 80 -- sudo kvm \
            -cpu host,+topoext,hv_relaxed,hv_spinlocks=0x1fff,hv-passthrough,+pae,+nx,kvm=on,+svm \
            -smp 2,cores=2 \
            -M q35,usb=on \
            -device usb-tablet \
            -m 4G \
            -device virtio-balloon-pci \
            -vga virtio \
            -net nic,netdev=n0,model=virtio-net-pci \
            -netdev user,id=n0,hostfwd=tcp::3389-:3389 \
            -boot c \
            -device virtio-serial-pci \
            -device virtio-rng-pci \
            -enable-kvm \
            -drive file="$file_name" \
            -drive if=pflash,format=raw,readonly=off,file=/usr/share/ovmf/OVMF.fd \
            -uuid e47ddb84-fb4d-46f9-b531-14bb15156336 \
            -vnc :0
        echo "Máy ảo đã khởi động mà không bật âm thanh."
    fi
}

# Main
update_and_install
mount_partition
select_os
ask_audio
download_file
start_vm
