N = 9; % Should be even

% cost data points
c = [...
  linspace(0,1,N);                               % Equidistant
  [ linspace(0,0.1,N/3) linspace(0.4,0.5,N/3) linspace(0.9,1,N/3) ]; % Three clusters (three tasks)
  linspace(0.5,0.5,N);                           % One cluster (one task)
  ];
c_labels = {'c-clus=no','c-clus=yes','c-clus=one',};

% feature data points
f = [...
  linspace(0,1,N);                               % Equidistant
  [ linspace(0,0.1,N/3) linspace(0.4,0.5,N/3) linspace(0.9,1,N/3)  ]; % Three clusters
  [ zeros(1,N/3) zeros(1,N/3) ones(1,N/3) ];                  % Binary feature
  ];
f_labels = {'f-clus=no','f-clus=yes','f-clus=bin'};

% feature relevance (orders cost values to be clustered with features or not)
f_rel = [...
  [ 1:3:N 2:3:N 3:3:N];
  1:N;
  ];
f_rel_labels = {'f-rel=no','f-rel=yes'};


clf
for ordering_within_cluster=1:2 % see comment below
  figure(ordering_within_cluster)
  count = 1;
  
  for c_i = 1:size(c,1)
    for f_i = 1:size(f,1)
      for f_rel_i = 1:size(f_rel,1)
        
        ordering = f_rel(f_rel_i,:);
        if (ordering_within_cluster==2)
          % If the ordering was 1 2 3 4 5 6 7 8 before
          % it will be          4 3 2 1 8 7 6 5 after.
          % This matters only for the special case when
          % c-clus=no, f-clus=no, f-rel=yes
          ordering = ordering([N/2:-1:1 N:-1:(N/2+1)]);
        end
        
        
        % Default marker color (for irrelevant features)
        color = [0.8 0 0];
        if (strcmp(f_rel_labels{f_rel_i},'f-rel=yes'))
          if (strcmp(c_labels{c_i},'c-clus=one'))
            % If there is only one cost cluster, there is only one task. Therefore,
            % no feature could be relevant to splitting, because there is nothing
            % to split. Change plotting color to indicate this
            color = [0.8 0.8 0.8];
          else
            % Indicate that a feature is relevant by making it green
            color = [0 0.8 0];
          end
        end
        
        subplot(size(c,1),size(f,1)*size(f_rel,1),count); count = count + 1;
        plot(f(f_i,:),c(c_i,ordering),'o','MarkerEdgeColor','none','MarkerFaceColor',color)
        
        feature = f(f_i,:);
        cost = c(c_i,ordering);
        if all(feature == 0 | feature ==1)
          %it is a binary feature
          split = 0.5;
        else
          split = (feature(2:end) + feature(1:end-1))/2;
        end
        %go through all possible splits, see which is the best
        p = [];
        for i_split = 1:length(split)
          c0 = cost(feature < split(i_split));
          c1 = cost(feature > split(i_split));
          n0 = length(c0);
          n1 = length(c1);
          s = sqrt(var(c0)^2/n0 + var(c1)^2/n1);
          t = (mean(c0) - mean(c1)) / s;
          v = min(n0,n1) - 1; %degrees of freedom
          %two-tailed test
          p(i_split) = 2*tcdf(t,v);
        end
        
        [pmin imin] = min(p);
        
        hold on;
        if pmin < 0.03
          plot([split(imin) split(imin)],[0 1],'g');
        end
        text(0.52,0.5, num2str(pmin),'FontSize',8);
        
        
        hold on
        plot(f(f_i,:),-0.2*ones(1,N),'o','MarkerEdgeColor','none','MarkerFaceColor',color)
        plot(-0.2*ones(1,N),c(c_i,:),'o','MarkerEdgeColor','none','MarkerFaceColor',color)
        hold off
        axis square
        axis([-0.2 1.2 -0.2 1.2])
        title([c_labels{c_i} ' ' f_labels{f_i} ' ' f_rel_labels{f_rel_i} ])
      end
    end
  end
end

