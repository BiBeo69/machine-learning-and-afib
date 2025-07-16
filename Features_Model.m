clc, clear, close all;

% 📂 Thư mục chứa PACs đã phát hiện
result_folder = 'E:\PACs_WSUM\paf-prediction-challenge-database-1.0.0\paf-prediction-challenge-database-1.0.0\results';

% 🏥 Nhóm bệnh nhân
groups = {'n_group', 'p_odd_group', 'p_even_group'};
group_labels = {'No PAF', 'PAF Odd', 'PAF Even'};

% ⏳ Cửa sổ thời gian (10, 15, 30 phút)
time_windows = [5, 10, 15, 20, 25, 30];
% Tham số WSUM
tau = 6.3;  % Tham số suy giảm (có thể điều chỉnh)
w = 0;      % Không dịch chuyển

% 📊 Khởi tạo biến lưu trữ kết quả
pac_features = struct();

% 🚀 Duyệt qua từng nhóm bệnh nhân
for g = 1:length(groups)
    group_name = groups{g};
    fprintf('\n🔹 Đang xử lý nhóm: %s\n', group_name);
    
    % Lấy danh sách file PACs của nhóm này
    files = dir(fullfile(result_folder, group_name, '*.mat'));
    
    % Khởi tạo lưu trữ đặc trưng PACs
    pac_features.(group_name) = struct();
    
    % Lặp qua từng bệnh nhân trong nhóm
    for f = 1:length(files)
        filename = files(f).name;
        file_path = fullfile(files(f).folder, filename);
        
        % Load PACs của bệnh nhân
        load(file_path, 'pac_all');

        % Loại bỏ bản ghi nếu không có PACs
        if isempty(pac_all)
            continue;
        end

        % ⏳ Tính toán đặc trưng PACs cho từng cửa sổ
        for w = 1:length(time_windows)
            window_size = time_windows(w);  % Đơn vị: phút
            T = window_size * 60 * 128; % Chuyen thanh so mau (fs = 128)
            % Tính tổng số PACs trong cửa sổ này
            % pac_count = sum(pac_all <= window_size * 60 * 128);  % fs = 128 Hz
            pac_window = pac_all(pac_all > T - window_size*60*128 & pac_all <= T);
            pac_window_sec = pac_window/(128*60);
            % Lọc các PACs trong cửa sổ
            % pac_window = pac_all(pac_all <= T);
            % Tính tổng số PACs trong cửa sổ này
            pac_count = length(pac_window);
            % Tần suất PACs (PACs/phút)
            pac_frequency = pac_count / window_size;
            
            % Khoảng RR trước PACs
            rr_intervals = diff(pac_all) / 128; % Đơn vị: giây
            rr_variability = std(rr_intervals);
            
            % PAC burden (% thời gian bị ảnh hưởng)
            pac_burden = length(unique(pac_all)) / (window_size * 60 * 128);
            
            % PAC clustering index (PAC density)
            if ~isempty(rr_intervals)
                pac_density = pac_count / range(pac_all) * 128;
            else
                pac_density = 0;
            end

            % Tính toán WSUM theo công thức của Zong et al
            if ~ isempty(pac_window);
                u_step = pac_window - T + w <0;
                wsum_value = sum(exp(pac_window_sec/tau).*u_step);
            else
                wsum_value = 0;
            end
            
            % Lưu kết quả vào struct
            % Chuẩn hóa tên file: bỏ phần mở rộng và thay "." bằng "_"
            clean_filename = regexprep(filename, '\.mat$', ''); % Bỏ đuôi .mat
            clean_filename = regexprep(clean_filename, '[^a-zA-Z0-9_]', '_'); % Thay dấu chấm/thanh ngang bằng "_"

            % Lưu vào struct với tên hợp lệ
            time_window_field = sprintf('w%dmin', window_size);

            % Lưu vào struct
             pac_features.(group_name).(clean_filename).(time_window_field) = struct(...
                'PAC_Count', pac_count, ...
                'PAC_Frequency', pac_frequency, ...
                'RR_Variability', rr_variability, ...
                'PAC_Burden', pac_burden, ...
                'PAC_Density', pac_density, ...
                'WSUM', wsum_value ...
            );
        end
    end
end

% 💾 Lưu kết quả vào file MAT
save('PACs_Features.mat', 'pac_features');
fprintf('\n✅ Đã tính toán xong đặc trưng PACs và lưu kết quả!\n');

