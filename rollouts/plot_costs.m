function plot_costs(folder)

cd(strcat('C:\Users\Francois\Documents\Laura\2013\task_splitting_laura\dmp_bbo\rollouts\',folder));
files = dir('cost*');
n_files = length(files);

task = task_arm_path;
n_per_update = 15;
c = [];
c_avg = [];
for i_file = 1:n_files
    cost_vars = csvread(files(i_file).name);
    cost = task.cost_function(task,cost_vars);
    c(end+1) = cost;
    if mod(i_file,n_per_update) ==0
        c_avg(end+1) = sum(c((i_file-n_per_update+1):i_file))/n_per_update;
    end
end
figure
subplot(1,2,1);
plot(c)
ylim([-0.05 1.05]);
subplot(1,2,2);
plot(c_avg)
ylim([-0.05 1.05]);

end