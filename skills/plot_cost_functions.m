function labels = plot_cost_functions(skill, fig, labels)
%assumes one degree of freedom

if nargin <3
    labels{1} = skill.name;
end
n_dims = length(skill.distributions.mean);
n_samples = length(skill.previous_experience);
figure(fig);
hold on;

for ii = 1:n_samples
   x(ii) = skill.previous_experience(ii).sample; 
   y(ii,:) = skill.previous_experience(ii).cost;
end

scatter(x,y(:,1));

if ~isempty(skill.subskills)
    for ii = 1:length(skill.subskills)
        labels{end +1} = skill.subskills(ii).name;
        plot_cost_functions(skill.subskills(ii), fig);
        %legend(labels);
    end
end


end