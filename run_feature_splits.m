function run_feature_splits(filename)

%if no filename, find most recent
if nargin <1
  listing = dir('*.mat');
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

feature_split_2D_gaussians(p,c,p_thresh,1);
feature_split_sliding(p,c,p_thresh,2);
feature_split_cluster_costs(p,c,p_thresh,3);

end