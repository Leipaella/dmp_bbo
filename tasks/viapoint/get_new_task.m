
function task = get_new_task(g, y0)

    which = rand(1);

    if which<0.3
      viapoint            = [0.45 0.7];
      viapoint_time_ratio =       0.3;  
    elseif which>0.7
      viapoint            = [0.4 0.7];
      viapoint_time_ratio =       0.3;  
    else
      viapoint            = [0.7 0.4];
      viapoint_time_ratio =       0.3; 
    end

    task = task_viapoint(viapoint,viapoint_time_ratio);

end