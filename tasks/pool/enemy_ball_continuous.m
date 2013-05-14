function [tasks percepts ntasks] = enemy_ball_continuous(goal)

%for a 5 x 5 grid of positions around the goal
xranges = goal(1)-20:10:goal(1)+20;
yranges = goal(2)-20:10:goal(2)+20;
ntasks = 25;
ii = 1;
for x = xranges
  for y = yranges
    balls.x = x;
    if x == goal(1)
      balls.y = goal(2) - 20;
    else
      balls.y = y;
    end
    balls.teams = [2];
    percepts(ii,1) = balls.x;
    percepts(ii,2) = balls.y;
    percepts(ii,3) = balls.x == goal(1);
    percepts(ii,4) = balls.x > goal(1); %is the ball to the right of the goal
    percepts(ii,5) = balls.y > goal(2); %is the ball behind the goal
    %percepts(ii,6) = sqrt((goal(1) - x)^2 + (goal(2) - y)^2);
    %percepts(ii,7) = atan2(goal(2) - y,goal(1) - x);
    tasks(ii) = task_pool(goal,balls,ii,25);
    ii = ii + 1;
  end
end

end