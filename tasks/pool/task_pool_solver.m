function [task_solver] = task_pool_solver



task_solver.perform_rollouts = @perform_rollouts_pool;
task_solver.plot_rollouts = @plot_rollouts_pool;


% Now comes the function that does the roll-out and visualization thereof
  function cost_vars = perform_rollouts_pool(task,thetas, plot_en) %#ok<INUSL>
    
    %thetas contain three variables.
    % the x position, the power, and the angle
    %sx = thetas(1);
    %power = thetas(2);
    %angle = thetas(3);
    
    sx = 25;
    power = thetas(1);
    %angle = pi/2;
    angle = thetas(2);
    N = length(task.balls.x);
    %teams is 1 for my team, 2 for the enemy team.
    [X Y] = billiardgame3([sx task.balls.x], [10 task.balls.y], [power zeros(1,N)],[angle zeros(1,N)],[1 task.balls.teams]);
    cost_vars.X = X(end,:);
    cost_vars.Y = Y(end,:);
    cost_vars.path.X = X;
    cost_vars.path.Y = Y;
    cost_vars.teams = [1 task.balls.teams];
    
    
  end

  function plot_rollouts_pool(axes_handle,task,cost_vars)
    
    if task.n < 3
    subplot(1,task.n,task.id,'replace');
    end
    %clf;
    title(strcat('Task ', num2str(task.id)));
    
    X = cost_vars.path.X;
    Y = cost_vars.path.Y;
    hold on
    w = 50;
    l = 100;
    N = size(X,2);
    plot([0 0 w w 0],[0 l l 0 0],'k');
    axis equal
    axis tight
    c = ['k'; 'r'];
    rad = 5;
    
    %for each ball
    for b = 1:N
      hold on;
      if ~isempty(cost_vars.teams)
        color = c(cost_vars.teams(b));
      else
        color = c(1);
      end
      %scatter(X(:,b),Y(:,b),rad^2*pi,color);
      plot(X(1,b)',Y(1,b)',strcat(color,'x'));
      plot(X(:,b)',Y(:,b)',color);
      scatter(X(end,b), Y(end,b),(rad)^2*pi,color);
    end
    plot(task.goal(1),task.goal(2),'gx');
    drawnow;
  end

end

