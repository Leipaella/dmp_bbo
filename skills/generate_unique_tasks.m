function [tasks percepts] = generate_unique_tasks(goal)

%task 1, enemy ball blocking goal, my ball far
balls.x(1) = goal(1);
balls.y(1) = goal(2) - 10;
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


% %task 3, both balls far
% balls.x(1) = goal(1) + 20;
% balls.y(1) = goal(2) + 20;
% balls.x(2) = goal(1) - 20;
% balls.y(2) = goal(2) + 20;
% balls.teams = [2 1];
% tasks(3) = task_pool(goal, balls);
% percepts(3,1) = 0;
% 
% 
% 
% %task 4, both balls near
% balls.x(1) = goal(1) + 8;
% balls.y(1) = goal(2);
% balls.x(2) = goal(1) - 8;
% balls.y(2) = goal(2);
% balls.teams = [2 1];
% tasks(4) = task_pool(goal, balls);
% percepts(4,1) = 1;


% balls.x(1) = goal(1) + 8;
% balls.y(1) = goal(2);
% balls.x(2) = goal(1) + 20;
% balls.y(2) = goal(2) + ;
% balls.teams = [2 1];
% tasks(4) = task_pool(goal, balls);



end