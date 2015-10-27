function out= proc_percentiles(epo, p, varargin)
%PROC_PERCENTILES - Classwise calculated percentiles
%
%Synopsis:
% EPO= proc_percentiles(EPO, <OPT>)
% EPO= proc_percentiles(EPO, CLASSES)
%
%Arguments:
% EPO -      data structure of epoched data
%            (can handle more than 3-dimensional data, the percentils are
%            calculated across the last dimension)
% p   -      [1 m] vector, with entries in the range 0..100. Produce
%            percentile values for the values given here. For scalar p, y is
%            a row vector containing Pth percentile of each column of X. For
%            vector p,the ith row of y is the p(i) percentile of each column
%            of X. For median calculation e.g. p=50;
%
% OPT struct or property/value list of optional arguments:
%  .Classes - classes of which the average is to be calculated,
%            names of classes (strings in a cell array), or 'ALL' (default)
%
% For compatibility PROC_AVERAGE can be called in the old format with CLASSES
% as second argument (which is now set via opt.Classes):
% CLASSES - classes of which the average is to be calculated,
%           names of classes (strings in a cell array), or 'ALL' (default)
%
%Returns:
% EPO           - updated data structure with fields
%  .x           - classwise percentiles
%  .N           - vector of epochs per class across which average was calculated
%  .percentiles - vector containing the percentiles
%
% Benjamin Blankertz
% 10-2015 miklody@tu-berlin.de

props= {  'Policy'   'mean' '!CHAR(mean nanmean median)';
          'Classes' 'ALL'   '!CHAR';
          'Std'      0      '!BOOL';
          'Stats'      0    '!BOOL';
          'Bonferroni' 0    '!BOOL';
          'Alphalevel' []   'DOUBLE'};

if nargin==0,
  out = props; return
end

misc_checkType(epo, 'STRUCT(x clab y)'); 
if nargin==3&&(iscellstr(varargin{1})||ischar(varargin{1}))
  opt.Classes = varargin{:};
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);        
epo = misc_history(epo);

%% delegate a special case:
if isfield(epo, 'yUnit') && isequal(epo.yUnit, 'dB'),
  out= proc_dBPercentiles(epo, varargin{:});
  return;
end

%%		  
classes = opt.Classes;

if ~isfield(epo, 'y'),
  warning('no classes label found: calculating average across all epochs');
  nEpochs= size(epo.x, ndims(epo.x));
  epo.y= ones(1, nEpochs);
  epo.className= {'all'};
end

if isequal(opt.Classes, 'ALL'),
  classes= epo.className;
end
if ischar(classes), classes= {classes}; end
if ~iscell(classes),
  error('classes must be given cell array (or string)');
end
nClasses= length(classes);

if max(sum(epo.y,2))==1,
  warning('only one epoch per class - nothing to average');
  out= proc_selectClasses(epo, classes);
  out.N= ones(1, nClasses);
  return;
end

out= epo;
%  clInd= find(ismember(epo.className, classes));
%% the command above would not keep the order of the classes in cell 'ev'
evInd= cell(1,nClasses);
for ic= 1:nClasses,
  clInd= find(ismember(epo.className, classes{ic},'legacy'));
  evInd{ic}= find(epo.y(clInd,:));
end

sz= size(epo.x);
out.x= zeros(prod(sz(1:end-1)), nClasses, numel(p));
out.y= eye(nClasses);
out.className= classes;
out.N= zeros(1, nClasses);
epo.x= reshape(epo.x, [prod(sz(1:end-1)) sz(end)]);
for ic= 1:nClasses,
    out.x(:,ic,:)= stat_percentiles(epo.x(:,evInd{ic}),p);
end
out.percentiles=p;

out.x= reshape(out.x, [sz(1:end-1) nClasses numel(p)]);

out.indexedByEpochs = {}; 

