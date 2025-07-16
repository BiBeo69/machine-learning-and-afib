%% Step 1
clc, clear, close all; 

% 📂 Thư mục chứa PACs đã phát hiện
result_folder = 'E:\PACs_WSUM\paf-prediction-challenge-database-1.0.0\paf-prediction-challenge-database-1.0.0\results';

% 🏥 Nhóm bệnh nhân
groups = {'n_group', 'p_odd_group', 'p_even_group'};
group_labels = {'No PAF', 'PAF Odd', 'PAF Even'};

% ⏳ Cửa sổ thời gian (5, 10, 15, 30 phút)
time_windows = [5, 10, 15, 20, 25, 30];
tau = 6.3;  % Tham số suy giảm (có thể điều chỉnh)
w = 0;      % Không dịch chuyển

% 📊 Khởi tạo biến lưu trữ kết quả
pac_features = struct();

% 🚀 Lưu trữ dữ liệu đặc trưng để kiểm định thống kê
stats_data = struct();

% Duyệt qua từng nhóm bệnh nhân
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

            % 📊 Lưu dữ liệu cho kiểm định thống kê
            if ~isfield(stats_data, time_window_field)
                stats_data.(time_window_field) = struct(...
                    'PAC_Frequency', [], ...
                    'RR_Variability', [], ...
                    'PAC_Burden', [], ...
                    'PAC_Density', [], ...
                    'WSUM', [], ...
                    'Groups', [] ...
                );
            end

            % Ghi dữ liệu vào danh sách
            stats_data.(time_window_field).PAC_Frequency = [stats_data.(time_window_field).PAC_Frequency; pac_frequency];
            stats_data.(time_window_field).RR_Variability = [stats_data.(time_window_field).RR_Variability; rr_variability];
            stats_data.(time_window_field).PAC_Burden = [stats_data.(time_window_field).PAC_Burden; pac_burden];
            stats_data.(time_window_field).PAC_Density = [stats_data.(time_window_field).PAC_Density; pac_density];
            stats_data.(time_window_field).WSUM = [stats_data.(time_window_field).WSUM; wsum_value];
            stats_data.(time_window_field).Groups = [stats_data.(time_window_field).Groups; g];
        end
    end
end

% 💾 Lưu kết quả vào file MAT
save('PACs_Features.mat', 'pac_features');
fprintf('\n✅ Đã tính toán xong đặc trưng PACs và lưu kết quả!\n');


% 🏥 Danh sách nhóm bệnh nhân
 % groups = {'n_group', 'p_odd_group', 'p_even_group'};
 groups = { 'n_group','p_even_group'};
% 🏷 Nhãn tương ứng (No PAF = 1, PAF Odd = 2, PAF Even = 3)
group_labels = [1, 2];

% ⏳ Cửa sổ thời gian (20, 25, 30 phút)
 time_windows = {'w5min','w10min','w15min','w20min','w25min','w30min'};
  % time_windows = {'w5min','w30min'};
% 📊 Khởi tạo ma trận dữ liệu và nhãn
feature_matrix = [];
labels = [];

for g = 1:length(groups)
    group_name = groups{g};
    fprintf('\n🔹 Xử lý nhóm: %s\n', group_name);

    % Danh sách bệnh nhân trong nhóm
    patients = fieldnames(pac_features.(group_name));

    % Lặp qua từng bệnh nhân
    for i = 1:length(patients)
        patient_id = patients{i};
        
        % Kiểm tra xem bệnh nhân có đủ dữ liệu không
        if all(isfield(pac_features.(group_name).(patient_id), time_windows))
            % Trích xuất đặc trưng ở các thời điểm khác nhau
            features = [];
            for t = 1:length(time_windows)
                win = time_windows{t};
                pac_data = pac_features.(group_name).(patient_id).(win);
                 % features = [features, pac_data.PAC_Burden, pac_data.PAC_Density, pac_data.WSUM];
                   features = [features, pac_data.WSUM,pac_data.PAC_Density];
            end
        
            % Lưu vào ma trận dữ liệu
            feature_matrix = [feature_matrix; features];
            labels = [labels; group_labels(g)];
        end
    end
end

% 📊 Kết quả
fprintf('\n✅ Đã tạo xong ma trận đặc trưng với kích thước: %d x %d\n', size(feature_matrix,1), size(feature_matrix,2));

% 💾 Lưu lại ma trận đặc trưng và nhãn
save('HMM_Input.mat', 'feature_matrix', 'labels');

%% Step 2: Chia tập dữ liệu thành Train/Test và Áp dụng SMOTE

load('HMM_Input.mat', 'feature_matrix', 'labels');

% Cố định seed để đảm bảo kết quả lặp lại
 rng(42);

% Chia tập dữ liệu thành 80% train, 20% test
cv = cvpartition(size(feature_matrix, 1), 'HoldOut', 0.2);
train_idx = training(cv);
test_idx = test(cv);

% Tách dữ liệu train/test
X_train = feature_matrix(train_idx, :);
y_train = labels(train_idx);
X_test = feature_matrix(test_idx, :);
y_test = labels(test_idx);

% Kiểm tra và cài đặt gói SMOTE nếu chưa có
if exist('smote', 'file') ~= 2
    addpath(genpath('path_to_smote_function')); % Cập nhật đường dẫn tới SMOTE
end

% Xác định các mẫu cần tăng bằng SMOTE
paf_odd_idx = find(y_train == 2);
paf_even_idx = find(y_train == 3);

X_minority = [X_train(paf_odd_idx, :); X_train(paf_even_idx, :)];
y_minority = [y_train(paf_odd_idx); y_train(paf_even_idx)];

% Áp dụng SMOTE
new_samples = 100;  % Số lượng mẫu muốn tạo thêm
[X_synthetic, y_synthetic] = smote(X_minority, y_minority, new_samples);

% Cập nhật tập train sau khi SMOTE
X_train = [X_train; X_synthetic];
y_train = [y_train; y_synthetic];

% Chuẩn hóa dữ liệu (có thể thử Standardization nếu cần)
X_train_norm = normalize(X_train);
X_test_norm = normalize(X_test);
%% Step 3: KNN

k_values = 1:10; % Thử từ 1 đến 10
accuracies = zeros(size(k_values));
precisions = zeros(size(k_values));
recalls = zeros(size(k_values));
f1_scores = zeros(size(k_values));
for i = 1:length(k_values)
    knn_model = fitcknn(X_train, y_train, 'NumNeighbors', k_values(i), 'Standardize', 1);
    y_pred = predict(knn_model, X_test);
    accuracies(i) = sum(y_pred == y_test) / length(y_test) * 100;
    % Tính TP, FP, FN, TN
    TP = sum((y_pred == 2) & (y_test == 2));
    FP = sum((y_pred == 2) & (y_test == 1));
    FN = sum((y_pred == 1) & (y_test == 2));
    TN = sum((y_pred == 1) & (y_test == 1));
    % Tính Precision, Recall, F1-score
    if TP + FP > 0
        precisions(i) = TP / (TP + FP);
    else
        precisions(i) = 0;
    end

    if TP + FN > 0
        recalls(i) = TP / (TP + FN);
    else
        recalls(i) = 0;
    end

    if precisions(i) + recalls(i) > 0
        f1_scores(i) = 2 * (precisions(i) * recalls(i)) / (precisions(i) + recalls(i));
    else
        f1_scores(i) = 0;
    end
end

% Hiển thị kết quả
disp('K | Accuracy (%) | Precision | Recall | F1-score');
disp('-------------------------------------------------');
for i = 1:length(k_values)
    fprintf('%d | %.2f%% | %.2f | %.2f | %.2f\n', k_values(i), accuracies(i), precisions(i), recalls(i), f1_scores(i));
end
% Vẽ đồ thị k vs. accuracy
figure;
plot(k_values, accuracies, '-o');
xlabel('Số k (Láng giềng gần nhất)');
ylabel('Độ chính xác (%)');
title('Chọn k tối ưu cho KNN');
grid on;

% Tìm giá trị k tối ưu
[best_acc, best_idx] = max(accuracies);
fprintf('📌 Giá trị k tối ưu: %d với độ chính xác %.2f%%\n', k_values(best_idx), best_acc);

%% Step 4
% Huấn luyện mô hình Random Forest
numTrees = 200; % Số lượng cây trong rừng
RF_model = TreeBagger(numTrees, X_train, y_train, 'Method', 'classification');

% Dự đoán trên tập test
y_pred_RF = str2double(predict(RF_model, X_test));

% Tính độ chính xác
accuracy_RF = sum(y_pred_RF == y_test) / length(y_test) * 100;
TP = sum((y_pred_RF == 2) & (y_test == 2));
    FP = sum((y_pred_RF == 2) & (y_test == 1));
    FN = sum((y_pred_RF == 1) & (y_test == 2));
    TN = sum((y_pred_RF == 1) & (y_test == 1));
     precisions = TP / (TP + FP);
fprintf('\n🌳 Độ chính xác Random Forest: %.2f%%\n', accuracy_RF);

%% Step 5
% Huấn luyện mô hình SVM
SVM_model = fitcsvm(X_train, y_train, 'KernelFunction', 'rbf', 'Standardize', true);

% Dự đoán trên tập test
y_pred_SVM = predict(SVM_model, X_test);

% Tính độ chính xác
accuracy_SVM = sum(y_pred_SVM == y_test) / length(y_test) * 100;
% Tính TP, FP, FN, TN
    TP = sum((y_pred_SVM == 2) & (y_test == 2));
    FP = sum((y_pred_SVM == 2) & (y_test == 1));
    FN = sum((y_pred_SVM == 1) & (y_test == 2));
    TN = sum((y_pred_SVM == 1) & (y_test == 1));
     precisions = TP / (TP + FP);
     recalls = TP / (TP + FN);
     f1_scores = 2 * (precisions * recalls )/ (precisions + recalls);


fprintf('\n📈 Độ chính xác SVM: %.2f%%\n', accuracy_SVM);

%% Step 6
% Danh sách tham số cần tối ưu
numTrees_list = [50, 100, 200, 300];  % Số cây trong Random Forest
minLeafSize_list = [1, 5, 10];        % Số mẫu tối thiểu trên mỗi lá
maxNumSplits_list = [10, 50, 100];    % Số lần chia tối đa trên mỗi cây

best_accuracy = 0;
best_precision = 0;
best_model = [];

% Lặp qua tất cả các bộ tham số
for numTrees = numTrees_list
    for minLeafSize = minLeafSize_list
        for maxNumSplits = maxNumSplits_list
            % Huấn luyện Random Forest với tham số hiện tại
            model = TreeBagger(numTrees, X_train, y_train, ...
                'Method', 'classification', ...
                'MinLeafSize', minLeafSize, ...
                'MaxNumSplits', maxNumSplits);
            
            % Dự đoán trên tập test
            predictions = str2double(predict(model, X_test));
            
            % Tính độ chính xác
            accuracy = sum(predictions == y_test) / length(y_test) * 100;
            TP = sum((predictions == 2) & (y_test == 2));
    FP = sum((predictions == 2) & (y_test == 1));
    FN = sum((predictions == 1) & (y_test == 2));
    TN = sum((predictions == 1) & (y_test == 1));
     precisions = TP / (TP + FP);
            
            % Kiểm tra nếu tốt hơn mô hình hiện tại
            if accuracy > best_accuracy
                best_accuracy = accuracy;
                best_precision = precisions;
                best_model = model;
            end

            fprintf('✅ numTrees: %d, minLeafSize: %d, maxNumSplits: %d → Accuracy: %.2f%%\n', ...
                numTrees, minLeafSize, maxNumSplits, accuracy);
        end
    end
end

% Xuất kết quả tốt nhất
fprintf('\n🏆 Best Model → Accuracy: %.2f%%\n', best_accuracy);

% Lưu mô hình tốt nhất
save('best_random_forest.mat', 'best_model');

%% Step 7
% Số k trong k-fold cross-validation
numFolds = 5;  

% Tạo phân vùng k-fold
cv = cvpartition(size(feature_matrix, 1), 'KFold', numFolds);

% Khởi tạo vector lưu trữ độ chính xác qua các fold
accuracy_scores = zeros(numFolds, 1);

for fold = 1:numFolds
    fprintf('🔄 Đang chạy Fold %d/%d\n', fold, numFolds);

    % Tạo tập huấn luyện và kiểm tra cho fold hiện tại
    trainIdx = training(cv, fold);
    testIdx = test(cv, fold);

    X_train = feature_matrix(trainIdx, :);
    y_train = labels(trainIdx);
    X_test = feature_matrix(testIdx, :);
    y_test = labels(testIdx);

    % Huấn luyện mô hình Random Forest
    model = fitcensemble(X_train, y_train, 'Method', 'Bag', 'NumLearningCycles', 100);

    % Dự đoán trên tập test
    y_pred = predict(model, X_test);

    % Tính độ chính xác
    accuracy_scores(fold) = sum(y_pred == y_test) / length(y_test);
end

% Tính độ chính xác trung bình
mean_accuracy = mean(accuracy_scores);
fprintf('✅ Độ chính xác trung bình qua %d folds: %.2f%%\n', numFolds, mean_accuracy * 100);

%% Step 8
% Số lượng Folds trong K-Fold Cross-Validation
numFolds = 5;

% Định nghĩa không gian tìm kiếm tham số
optVars = [
    optimizableVariable('numTrees', [50, 300], 'Type', 'integer')
    optimizableVariable('minLeafSize', [1, 20], 'Type', 'integer')
    optimizableVariable('maxNumSplits', [10, 100], 'Type', 'integer')
];

% Chạy Bayesian Optimization với K-Fold Cross-Validation
results = bayesopt(@(params) randomForestObjective(params, feature_matrix, labels, numFolds), ...
    optVars, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', ...
    'MaxObjectiveEvaluations', 30, ...  % Số lần thử nghiệm tối đa
    'Verbose', 1);

% Hiển thị tham số tốt nhất
bestParams = results.XAtMinObjective;
disp('📌 Tham số tối ưu:');
disp(bestParams);


