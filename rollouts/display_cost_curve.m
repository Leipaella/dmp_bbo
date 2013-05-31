function display_cost_curve(skill_list)


for i_skill = 1:numel(skill_list)
    hold on
    skill = skill_list(i_skill).skill;
    avg_cost = [];
    for i_update = 1:numel(skill.learning_history)
        history = skill.learning_history(i_update);
        avg_cost(i_update) = mean(history.costs);
    end
    plot(avg_cost);
end

end