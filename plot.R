library(tidyverse)

d0 <- feather::read_feather('cells.feather')
stims <- feather::read_feather("stim_table.feather")

d <- d0 %>%
  group_nest(stim) %>%
  bind_cols(stims) %>%
  unnest(cols=data) %>%
  filter(spatial_frequency>0) %>%
  mutate(spatial_frequency = round(spatial_frequency, digits = 2)) %>%
  group_by(cell, orientation, spatial_frequency, phase) %>%
  summarise(
    sem = sd(value) / sqrt(n()),
    value = mean(value),
    n = n(),
    .groups = "drop") 

dd <- d %>%
  group_nest(cell, spatial_frequency, phase) %>%
  mutate(avg_value = map_dbl(data, ~mean(.x$value))) %>%
  unnest(data) %>%
  group_by(cell, phase, orientation) %>%
  mutate(highest_sf = spatial_frequency[which.max(avg_value)]) %>%
  ungroup() %>%
  select(-avg_value)  %>%
  group_nest(cell, orientation, phase) %>%
  mutate(avg_value = map_dbl(data, ~mean(.x$value))) %>%
  unnest(data) %>%
  group_by(cell, phase, spatial_frequency) %>%
  mutate(highest_ori = orientation[which.max(avg_value)]) %>%
  ungroup() %>%
  select(-avg_value) %>%
  group_nest(cell, orientation, spatial_frequency) %>%
  mutate(avg_value = map_dbl(data, ~mean(.x$value))) %>%
  unnest(data) %>%
  group_by(cell, orientation, spatial_frequency) %>%
  mutate(highest_phase = phase[which.max(avg_value)]) %>%
  ungroup() %>%
  select(-avg_value)
  
dd %>%
  mutate(phase = factor(phase)) %>%
  filter(spatial_frequency == highest_sf) %>%
  filter(between(cell, 0, 50)) %>%
  ggplot(aes(x=orientation, y=value, color=phase)) +
  geom_line() +
  # geom_errorbar(aes(ymin=lower, ymax=upper)) +
  facet_wrap(~cell, scales="free")


dd %>%
  mutate(spatial_frequency = factor(spatial_frequency)) %>%
  filter(phase == highest_phase) %>%
  filter(between(cell, 101, 150)) %>%
  ggplot(aes(x=orientation, y=value, color=spatial_frequency)) +
  geom_line() +
  # geom_errorbar(aes(ymin=lower, ymax=upper)) +
  facet_wrap(~cell, scales="free")


dd %>%
  filter(spatial_frequency == highest_sf) %>%
  whoppeR::WISEsummary(
    dependentvars = "value",
    betweenvars = c("highest_ori", "highest_phase"),
    withinvars = c("phase","orientation"),
    idvar = "cell") %>%
  ggplot(aes(x=orientation, y=value_mean, color=phase)) +
  geom_line() +
  facet_grid(highest_ori~highest_phase) +
  # geom_errorbar(aes(ymin=value_CI_lower, ymax=value_CI_upper))
  geom_errorbar(aes(ymin=value_mean-value_sem, ymax=value_mean+value_sem)) 


