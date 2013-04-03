function Pool_example_visualize(obj, goal)

[tasks percepts] = generate_unique_tasks(goal);


task_solver = task_pool_solver;

for i = 1:size(tasks,2)
  obj.solve_task_instance(tasks(i),task_solver,percepts(i,:),1);
end

end