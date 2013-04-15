function [tasks percepts ntasks] = enemy_ball_continuous(goal)

%for a 5 x 5 grid of positions around the goal
xranges = goal(1)-20:10:goal(1)+20;
yranges = goal(2)-20:10:goal(2)+20;
ntasks = 25;
ii = 1;
for x = xranges
  for y = yranges
    balls.x = x;
    balls.y = y;
    balls.teams = [2];
    percepts(ii,1) = x;
    percepts(ii,2) = y;
    %percepts(ii,3) = ii;
    percepts(ii,3) = x > goal(1); %is the ball to the right of the goal
    percepts(ii,4) = y > goal(2); %is the ball behind the goal
    %percepts(ii,6) = sqrt((goal(1) - x)^2 + (goal(2) - y)^2);
    %percepts(ii,7) = atan2(goal(2) - y,goal(1) - x);
    tasks(ii) = task_pool(goal,balls,ii,25);
    ii = ii + 1;
  end
end

end