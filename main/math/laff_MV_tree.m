function [] = laff_MV_tree(H, input_name, output_name, settings)
% this script generates FPGA synthesisable C code for dense matrxi vector
% multiplication y_out = H*x_in with a reduction tree approach


if (~isfield (settings, 'adder_lat')); settings.adder_lat = 8; end
 
 ADDER_LATENCY = settings.adder_lat; % max allowed adder latency (usually in the range 8 to 12 clock cycles)
 
data_t = 'data_t_laff_out_out';
 
 
 SIZE = size(H,1);

 
 %% call the function from main file

fileID = fopen('user_laff_main.cpp','a');
fprintf(fileID,strcat('mv_mult(', input_name, ',', output_name, ')\n'));
flcose(fileID);


%% generate code 
fileID = fopen('user_laff_func.h','a');
fprintf(fileID,'#define SIZE %d\n', SIZE);

fprintf(fileID,strcat('void mv_mult(',data_t,' y_out[SIZE],',data_t,' x_in[SIZE]);\n'));
fclose(fileID);


fileID = fopen('user_laff_func.cpp','a');
fprintf(fileID,'\n');
fprintf(fileID,strcat('void mv_mult(',data_t,' y_out[SIZE],',data_t,' x_in[SIZE])\n'));
fprintf(fileID,strcat('{\n'));
fprintf(fileID,strcat('\tshort i, j;\n'));
fprintf(fileID,strcat('\tfloat sum;\n\n'));
% print the matrix
fprintf(fileID,'\t// matrix \n');
tmp_mat = H(:,:);
fprintf(fileID,strcat('\t', data_t, ' H[SIZE][SIZE] = {',sprintf('%2.16f,' , reshape(tmp_mat.',[],1)),'};\n\n'));

fprintf(fileID,strcat('\tL1:for(i = 0; i < SIZE; i++)\n'));
fprintf(fileID,strcat('\t{\n'));
fprintf(fileID,strcat('\t\t#pragma HLS PIPELINE\n'));
fprintf(fileID,strcat('\t\tsum = 0;\n'));
fprintf(fileID,strcat('\t\tL2: for(j = 0; j < SIZE; j++)\n'));
fprintf(fileID,strcat('\t\t{\n'));
fprintf(fileID,strcat('\t\t\tsum += H[i][j]*x_in[j];\n'));
fprintf(fileID,strcat('\t\t}\n'));
fprintf(fileID,strcat('\t\ty_out[i] = sum;\n'));
fprintf(fileID,strcat('\t}\n'));

fprintf(fileID,strcat('}\n'));
fclose(fileID);

% %% copy code to protoip project
%  copyfile('user_mv_mult.cpp','ip_design/src/')
%  copyfile('user_mv_mult.h','ip_design/src/')
end
