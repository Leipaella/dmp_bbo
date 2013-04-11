function [tasks percepts ntasks] = generate_unique_tasks(goal)

ntasks = 2;

%task 1, enemy ball blocking goal, my ball far
balls.x(1) = goal(1);
balls.y(1) = goal(2)-8;
balls.x(2) = goal(1) - 20;
balls.y(2) = goal(2) + 20;
balls.teams = [2 1];
tasks(1) = task_pool(goal, balls,1,2);
percepts(1,1) = 0;
percepts(1,2) = round(rand(1)); %useless feature

%task 2, both balls far
balls.x(1) = goal(1) - 20;
balls.y(1) = goal(2) + 20;
balls.x(2) = goal(1) + 20;
balls.y(2) = goal(2) + 20;
balls.teams = [1 2];
tasks(2) = task_pool(goal, balls,2,2);
percepts(2,1) = 1;
percepts(2,2) = round(rand(1)); %useless feature

[tasks, percepts ntasks] = enemy_ball_continuous(goal);

end