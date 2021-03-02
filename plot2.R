library(tidyverse)

stims <- feather::read_feather("stim_table.feather") %>%
  select(-start, -end)

# peak <- feather::read_feather("peak.feather")

d <- feather::read_feather('cells.feather') %>%
  filter(!cell=="dx") %>%
  group_nest(stim) %>%
  bind_cols(stims) %>%
  unnest(cols=data) %>%
  filter(spatial_frequency>0) %>% # zero means blank stimulus
  mutate(spatial_frequency = round(spatial_frequency, digits = 2)) %>%
  group_by(cell, orientation, spatial_frequency, phase) %>%
  summarise(
    sem = sd(value) / sqrt(n()),
    value = mean(value),
    n = n(),
    .groups = "drop") 

d %>%
  mutate(spatial_frequency = factor(spatial_frequency)) %>%
  filter(cell == "662225105") %>%
  ggplot(aes(x=orientation, y=value, color=spatial_frequency)) +
  geom_line() +
  # geom_errorbar(aes(ymin=lower, ymax=upper)) +
  facet_wrap(~phase)

d %>%
  mutate(spatial_frequency = factor(spatial_frequency)) %>%
  filter(cell == "662226627") %>%
  ggplot(aes(x=orientation, y=value, color=factor(spatial_frequency))) +
  geom_line() +
  # geom_errorbar(aes(ymin=lower, ymax=upper)) +
  facet_wrap(~phase)

dd <- d %>%
  group_nest(cell, spatial_frequency) %>%
  mutate(avg_value = map_dbl(data, ~mean(.x$value))) %>%
  unnest(data) %>%
  group_by(cell, orientation) %>%
  mutate(highest_sf = spatial_frequency[which.max(avg_value)]) %>%
  ungroup() %>%
  select(-avg_value)  %>%
  group_nest(cell, orientation) %>%
  mutate(avg_value = map_dbl(data, ~mean(.x$value))) %>%
  unnest(data) %>%
  group_by(cell, spatial_frequency) %>%
  mutate(highest_ori = orientation[which.max(avg_value)]) %>%
  ungroup() %>%
  select(-avg_value)
  


dd %>%
  mutate(spatial_frequency = factor(spatial_frequency)) %>%
  whoppeR::WISEsummary(
    dependentvars = "value",
    betweenvars = c("highest_ori", "highest_sf"),
    withinvars = c("spatial_frequency","orientation"),
    idvar = "cell") %>%
  ggplot(aes(x=orientation, y=value_mean, color=spatial_frequency)) +
  geom_line() +
  facet_grid(highest_ori~highest_sf) +
  # geom_errorbar(aes(ymin=value_CI_lower, ymax=value_CI_upper))
  geom_errorbar(aes(ymin=value_mean-value_sem, ymax=value_mean+value_sem)) 


