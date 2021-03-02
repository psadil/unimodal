library(tidyverse)

stims <- feather::read_feather("stim_table_dg1.feather") %>%
  select(-start, -end)

# peak <- feather::read_feather("peak.feather")

d <- feather::read_feather('cells_dg1.feather') %>%
  filter(!cell=="dx") %>%
  group_nest(stim) %>%
  bind_cols(stims) %>%
  unnest(cols=data) %>%
  filter(blank_sweep==0) %>% 
  mutate(temporal_frequency = factor(temporal_frequency)) %>%
  whoppeR::WISEsummary(
    dependentvars = "value",
    withinvars = c("temporal_frequency","orientation"),
    betweenvars = "cell",
    idvar = "cell") %>%
  rename(direction=orientation)

d %>%
  # group_by(cell) %>%
  # filter(between(mean(value_mean), .5, .8 )) %>%
  # ungroup() %>%
  filter(cell %in% c("539928195","539928165","539926663","539927551")) %>%
  rename(`Temporal Frequency` = temporal_frequency) %>%
  ggplot(aes(x=direction, y=value_mean, color=`Temporal Frequency`)) +
  geom_line() +
  # geom_errorbar(aes(ymin=value_CI_lower, ymax=value_CI_upper)) +
  facet_wrap(~cell) +
  scale_color_viridis_d(option="inferno", end=0.8) +
  ylab(expression(paste(frac(paste(Delta," F"), F)) )) +
  scale_x_continuous(
    name = "Direction",
    breaks = seq(0,360-360/8, length.out = 8),
    labels = seq(0,360-360/8, length.out = 8)) +
  theme(
    strip.background = element_blank(),
    strip.text = element_blank(),
    legend.position = "bottom") +
  ggsave(
    "direction-tuning.png")

