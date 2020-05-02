function [reduced_svi_mod] = makeSviModelReduce(svi_mod_, t_)
% Function to reduce SVI model
% In
%   svi_mod_ [struct]: Full SVI parametrization
%   t_ [float]: Tenor to get single slice
% Out
%   reduced_svi_mod [struct]: Single SVI parametrization

idx = (svi_mod_.ts == t_);
for field = fieldnames(svi_mod_)'
    if (length(svi_mod_.(field{1})) == length(idx))
        reduced_svi_mod.(field{1}) = svi_mod_.(field{1})(idx);
    elseif (length(svi_mod_.(field{1})) == 1)
        if isa(svi_mod_.(field{1}),'function_handle')
            reduced_svi_mod.(field{1}) = svi_mod_.(field{1});
        else
            reduced_svi_mod.(field{1}) = svi_mod_.(field{1})(1);
        end
    end
end

end

