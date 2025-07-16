clc, clear, close all;

% 📂 Thư mục chứa PACs đã phát hiện
result_folder = 'E:\PACs_WSUM\paf-prediction-challenge-database-1.0.0\paf-prediction-challenge-database-1.0.0\results';

% 🏥 Nhóm bệnh nhân
groups = {'n_group', 'p_odd_group', 'p_even_group'};
group_labels = {'No PAF', 'PAF Odd', 'PAF Even'};
fs = 128;

% ⏳ Cửa sổ thời gian (10, 15, 30 phút)
time_windows = [5, 10, 15, 20, 25, 30];

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
            
            % Tính tổng số PACs trong cửa sổ này
            pac_count = sum(pac_all <= window_size * 60 * 128);  % fs = 128 Hz
            
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
                'PAC_Density', pac_density ...
            );
        end
    end
end

% 💾 Lưu kết quả vào file MAT
save('PACs_Features.mat', 'pac_features');
fprintf('\n✅ Đã tính toán xong đặc trưng PACs và lưu kết quả!\n');

%% 📊 So sánh PACs giữa các nhóm bệnh nhân
close all;

metrics = {'PAC_Frequency', 'RR_Variability', 'PAC_Burden', 'PAC_Density'};
group_names = {'Non PAF', 'Xa PAF', 'Trước PAF'}; % Nhãn hiển thị trên boxplot
 for m = 1:length(metrics)
    all_data = [];  % Danh sách chứa giá trị của tất cả nhóm
    group_idx = []; % Danh sách nhãn nhóm tương ứng
for w = 1:length(time_windows)
    window_size = time_windows(w);
    figure;
    hold on;
    title(sprintf('Comparison of %s between Groups (Window w%dmin)', metrics{m}, window_size), 'FontSize', 14);
    ylabel(metrics{m});
    xticklabels(group_labels);
    
    data = {};
    for g = 1:length(groups)
        group_name = groups{g};
        values = [];
        
        % Duyệt qua các bệnh nhân trong nhóm
        patients = fieldnames(pac_features.(group_name));
        for p = 1:length(patients)
            patient_data = pac_features.(group_name).(patients{p});
            window_name = sprintf('w%dmin', window_size);
            
            if isfield(patient_data, window_name)
                values = [values, patient_data.(window_name).(metrics{m})];
            end
        end
        data{g} = values;
    end
    
    all_data = [];
    group_idx = [];
    
    for g = 1:length(data)
        all_data = [all_data; data{g}(:)];
        group_idx = [group_idx; repmat(g, numel(data{g}), 1)];
    end

    % Vẽ boxplot cho cửa sổ thời gian cụ thể
    figure;
    boxplot(all_data, group_idx, 'Labels', group_labels, 'Notch', 'on');
    grid on;
    title(sprintf('Comparison of %s (Window %d min)', metrics{m}, window_size), 'FontSize', 14);
    ylabel('Feature Value', 'FontSize', 12);
end
 end

% 🚀 Duyệt qua từng đặc trưng PAC
% for m = 1:length(metrics)
%     all_data = [];  % Danh sách chứa giá trị của tất cả nhóm
%     group_idx = []; % Danh sách nhãn nhóm tương ứng
% 
%     figure;
%     hold on;
%     title(sprintf('Comparison of %s between Groups', metrics{m}), 'FontSize', 14);
%     ylabel(metrics{m}, 'FontSize', 12);
% 
%     for g = 1:3  % Chỉ lấy 3 nhóm: NonPAF, Xa PAF, Trước PAF
%         group_name = groups{g};
%         values = [];
% 
%         % Duyệt qua từng bệnh nhân trong nhóm
%         patients = fieldnames(pac_features.(group_name));
%         for p = 1:length(patients)
%             patient_data = pac_features.(group_name).(patients{p});
% 
%             % Duyệt qua các cửa sổ thời gian (5, 10, 15, 30 phút)
%             for w = 1:length(time_windows)
%                 window_name = sprintf('w%dmin', time_windows(w));
% 
%                 if isfield(patient_data, window_name) && isfield(patient_data.(window_name), metrics{m})
%                     values = [values; patient_data.(window_name).(metrics{m})];
%                 end
%             end
%         end
% 
%         % Kiểm tra nếu nhóm này có dữ liệu hợp lệ
%         if ~isempty(values)
%             all_data = [all_data; values];
%             group_idx = [group_idx; repmat(g, numel(values), 1)];
%         else
%             fprintf('⚠ Nhóm %s không có dữ liệu cho %s\n', group_name, metrics{m});
%         end
%     end
% 
%     % Kiểm tra số lượng điểm dữ liệu
%     disp(['Tổng số giá trị của ', metrics{m}, ': ', num2str(length(all_data))]);
%     disp(['Tổng số nhãn nhóm của ', metrics{m}, ': ', num2str(length(group_idx))]);
% 
%     % 📊 Vẽ boxplot
%     if ~isempty(all_data)
%         boxplot(all_data, group_idx, 'Labels', group_names, 'Notch', 'on');
%         grid on;
%     else
%         disp(['⚠ Không có dữ liệu để vẽ boxplot cho ', metrics{m}]);
%     end
% 
% end

fprintf('\n✅ Hoàn tất so sánh PACs giữa các nhóm bệnh nhân!\n');
% for m = 1:length(metrics)
%     figure;
%     hold on;
%     title(sprintf('Comparison of %s between Groups', metrics{m}), 'FontSize', 14);
%     ylabel(metrics{m});
%     xticklabels(group_labels);
% 
%     data = {};
%     for g = 1:length(groups)
%         group_name = groups{g};
%         values = [];
% 
%         % Duyệt qua các bệnh nhân trong nhóm
%         patients = fieldnames(pac_features.(group_name));
%         for p = 1:length(patients)
%             patient_data = pac_features.(group_name).(patients{p});
%             for w = 1:length(time_windows)
%                 window_name = sprintf('w%dmin', time_windows(w));
%                 if isfield(patient_data, window_name)
%                     values = [values, patient_data.(window_name).(metrics{m})];
%                 end
%             end
%         end
% 
%         % Lưu dữ liệu để vẽ boxplot
%         data{g} = values;
%     end
% 
%     % all_data = [];  % Danh sách chứa giá trị của tất cả nhóm
%     % group_idx = []; % Danh sách nhãn nhóm tương ứng
%     % 
%     % for g = 1:length(data)
%     % all_data = [all_data; data{g}(:)];  % Chuyển về vector cột và nối vào
%     % group_idx = [group_idx; repmat(g, numel(data{g}), 1)]; % Gán chỉ mục nhóm
%     % end
%     % 
%     % % Kiểm tra kết quả:
%     % disp('Tổng số giá trị:'); disp(length(all_data));
%     % disp('Tổng số nhãn nhóm:'); disp(length(group_idx));
%     % 
%     % % Vẽ boxplot
%     % figure;
%     % boxplot(all_data, group_idx, 'Labels', group_labels);
%     % grid on;
%     % title('Comparison of PAC Features between Groups');
%     all_data = [];  % Danh sách chứa giá trị của tất cả nhóm
%     group_idx = []; % Danh sách nhãn nhóm tương ứng
%     group_names = {'Non PAF', 'Xa PAF', 'Trước PAF'}; % Nhãn hiển thị trên boxplot
%     % group_names = { 'No PAF', 'PAF'};
% 
% % Chỉ lấy dữ liệu của No PAF và PAF
%     selected_groups = [1, 2, 3]; % Chỉ lấy nhóm 1 (No PAF) và nhóm 2+3 (PAF)
%     % 
%     % for g = selected_groups
%     %     if g == 1
%     %         % Nhóm No PAF giữ nguyên
%     %         all_data = [all_data; data{g}(:)];
%     %         group_idx = [group_idx; repmat(1, numel(data{g}), 1)];
%     %     else
%     %         % Nhóm PAF (gộp PAF Odd + PAF Even)
%     %         all_data = [all_data; data{g}(:)];
%     %         group_idx = [group_idx; repmat(2, numel(data{g}), 1)];
%     %     end
%     % end
% 
%     for g = selected_groups
%         all_data = [all_data; data{g}(:)];
%         group_idx = [group_idx; repmat(g, numel(data{g}), 1)];
%     end
% 
% % Chuyển đổi chỉ mục nhóm (1 → 1, 2 → 2, 3 → 3)
%     group_idx(group_idx == 1) = 1;  % NonPAF
%     group_idx(group_idx == 2) = 2;  % Xa PAF
%     group_idx(group_idx == 3) = 3;  % Trước PAF
% 
%     % Kiểm tra tổng số giá trị và nhãn nhóm
%     disp('Tổng số giá trị:'); disp(length(all_data));
%     disp('Tổng số nhãn nhóm:'); disp(length(group_idx));
% 
%     % Vẽ boxplot
%     figure;
%     boxplot(all_data, group_idx, 'Labels', group_names, 'Notch', 'on');
%     grid on;
%     title('Comparison of PAC Features: NonPAF vs Xa PAF vs Trước PAF', 'FontSize', 14);
%     ylabel('Feature Value', 'FontSize', 12);
% 
% 
% end
% 
% fprintf('\n✅ Hoàn tất so sánh PACs giữa các nhóm bệnh nhân!\n');
