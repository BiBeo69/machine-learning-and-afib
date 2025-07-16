% Đọc danh sách file trong thư mục Database
clc, clear, close all
data_path = 'E:\PACs_WSUM\paf-prediction-challenge-database-1.0.0\paf-prediction-challenge-database-1.0.0';  
files = dir(fullfile(data_path, '*.dat')); % List patient folders
% Khởi tạo danh sách nhóm bệnh nhân
n_group = {};  % Nhóm không có PAF
p_odd_group = {};  % Nhóm có PAF (p_odd)
p_even_group = {}; % Nhóm có PAF (p_even)
t_group = {};  % Nhóm test

for i = 1:length(files)
    filename = files(i).name;
    if startsWith(filename,'n')
        n_group = [n_group; {filename}];
    
    % Kiểm tra nhóm bệnh nhân dựa trên ký tự đầu tiên
    elseif startsWith(filename, 'p')
    record_id = str2double(regexp(filename, '\d+', 'match', 'once'));
    
    if ~isnan(record_id)  % Chỉ xử lý nếu record_id hợp lệ
        if mod(record_id, 2) == 1
            p_odd_group{end+1} = filename;
        else
            p_even_group{end+1} = filename;
        end
    else
        warning('Không thể trích xuất record_id từ: %s', filename);
    end     
    elseif startsWith(filename, 't')
        t_group = [t_group; {filename}];  % Nhóm test
    end
end

% Hiển thị kết quả
fprintf('Nhóm không có PAF (n): %d bản ghi\n', length(n_group));
fprintf('Nhóm PAF xa cơn (p_odd): %d bản ghi\n', length(p_odd_group));
fprintf('Nhóm PAF ngay trước cơn (p_even): %d bản ghi\n', length(p_even_group));
fprintf('Nhóm test (t): %d bản ghi\n', length(t_group));
