function run_feature_splits(filename)

%if no filename, find most recent
if nargin <1
  listing = dir('*.mat');
  if isempty(listing)
    disp('No .mat files are in the directory!');
    return;
  end
  
  for ii = 1:length(listing)
    dates(ii)=datenum(listing(ii).date);
  end
  [~,ind] = max(dates);
  filename = listing(ind).name;
end
load(filename);

for ii = 1:obj.K
  p(ii,:) = obj.previous_experience(end-ii+1).percept;
  c(ii,:) = obj.previous_experience(end-ii+1).cost;
end

p_thresh = 0.5;

f = figure(1);
set(f,'name','2D Gaussians');
feature_split_2D_gaussians(p,c,p_thresh,1);

f = figure(2);
set(f,'name','Sliding split value');
feature_split_sliding(p,c,p_thresh,2);

f = figure(3);
set(f,'name','Cluster costs');
feature_split_cluster_costs(p,c,p_thresh,3);

end