# TODO: Move Forecast Processing to Frontend

## Backend Changes
- [ ] Remove `/participation/forecast` route from `routes/api.php`
- [ ] Remove `getParticipationForecastPerYear` method from `ParticipationController.php`

## Frontend Changes
- [ ] Update `AdminDashboard.vue` to fetch raw participations instead of forecast data
- [ ] Implement forecast processing logic in JavaScript:
  - [ ] Group participations by event and year
  - [ ] Aggregate total participations per event per year
  - [ ] Calculate moving averages
  - [ ] Calculate exponential smoothing
  - [ ] Generate forecasts for future years
- [ ] Update chart rendering functions to use processed data
- [ ] Ensure charts display per event aggregation correctly

## Testing
- [ ] Test frontend processing and chart rendering
- [ ] Verify aggregation per event per year
