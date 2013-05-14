function display_z(skill)

%show the z-progression
z_mean = [];
z_mean = [];
for i = 1:length(skill.learning_history)
    dist = skill.learning_history(i).distributions;
    z_mean(i) = dist(9).mean(1);
    z_var(i) = dist(9).covar(1,1);
end
figure
errorbar(z_mean,sqrt(z_var));
xlabel('Update')
ylabel('Goal Z-position')
title('Should be moving upward');



end