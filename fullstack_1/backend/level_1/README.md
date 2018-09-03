# Intro

In this test, you are going to work on objectives, the main feature of javelo!

An objective represents a task that a user should accomply within a certain amount of time.

This feature aims to help these users planify well those tasks, and track their progression in order to accomplish them smoothly and on time.

Example of a real life objective :

```
{
  id: 17548,
  title: "Make 50 blank tests to be trained for the javelo challenge",
  start: 0,
  start_date: '2017-12-01',
  end_date: '2018-09-31',
  target: 50,
  unit: 'number'
}
```

# Level 1 : Achievement in percentage

In this level, we are intersted in some records of objective's progress. For each one you should calculate the corresponding `progress` value.

This progress is the percentage of accomplishement the value of the `progress_record` represents for the objective.
