# sql works

    Code
      orbital_sql(obj, con)
    Output
      <SQL> (`cyl` - 6.1875) / 1.785922 AS cyl
      <SQL> (`disp` - 230.7219) / 123.9387 AS disp
      <SQL> (`hp` - 146.6875) / 68.56287 AS hp
      <SQL> (`drat` - 3.596562) / 0.5346787 AS drat
      <SQL> (`wt` - 3.21725) / 0.9784574 AS wt
      <SQL> (`qsec` - 17.84875) / 1.786943 AS qsec
      <SQL> (`vs` - 0.4375) / 0.5040161 AS vs
      <SQL> (`am` - 0.40625) / 0.4989909 AS am
      <SQL> (`gear` - 3.6875) / 0.7378041 AS gear
      <SQL> (`carb` - 2.8125) / 1.6152 AS carb
      <SQL> (((((((((20.09062 + (`cyl` * -0.199024)) + (`disp` * 1.652752)) + (`hp` * -1.472876)) + (`drat` * 0.4208515)) + (`wt` * -3.635267)) + (`qsec` * 1.467153)) + (`vs` * 0.1601576)) + (`am` * 1.25757)) + (`gear` * 0.4835664)) + (`carb` * -0.322102) AS .pred

# sql works for glmnet classification

    Code
      orbital_sql(obj, con)
    Output
      <SQL> CASE
      WHEN ((1 / (1 + EXP(-((6.750.5 + (`disp` * -0.003776033)) + (`hp` * -0.04870484))))) > 0.5) THEN '1'
      ELSE '0'
      END AS .pred_class
      <SQL> 1 - (1 / (1 + EXP(-((6.750.5 + (`disp` * -0.003776033)) + (`hp` * -0.04870484))))) AS .pred_0
      <SQL> 1 - `.pred_0` AS .pred_1

# sql works for glmnet multiclass

    Code
      orbital_sql(obj, con)
    Output
      <SQL> (6.071777 + (`Sepal.Width` * 1.747431)) + (`Petal.Length` * -2.499172) AS setosa
      <SQL> 4.440574 AS versicolor
      <SQL> ((-10.51235 + (`Sepal.Width` * -1.098369)) + (`Petal.Length` * 1.700646)) + (`Petal.Width` * 5.920357) AS virginica
      <SQL> CASE
      WHEN (`setosa` >= `versicolor` AND `setosa` >= `virginica`) THEN 'setosa'
      WHEN (`versicolor` >= `setosa` AND `versicolor` >= `virginica`) THEN 'versicolor'
      ELSE 'virginica'
      END AS .pred_class
      <SQL> (EXP(`setosa`) + EXP(`versicolor`)) + EXP(`virginica`) AS norm
      <SQL> EXP(`setosa`) / `norm` AS .pred_setosa
      <SQL> EXP(`versicolor`) / `norm` AS .pred_versicolor
      <SQL> EXP(`virginica`) / `norm` AS .pred_virginica

# sql works for earth classification

    Code
      orbital_sql(obj, con)
    Output
      <SQL> CASE
      WHEN ((1 - 1 / (1 + EXP((1.863314 + (CASE WHEN (`hp` > 105) THEN (`hp` - 105) WHEN NOT (`hp` > 105) THEN 0 END * -017198)) + (CASE WHEN (`hp` > 175) THEN (`hp` - 175) WHEN NOT (`hp` > 175) THEN 0 END * -2.746445)))) > 0.5) THEN '1'
      ELSE '0'
      END AS .pred_class
      <SQL> 1 - (1 - 1 / (1 + EXP((1.863314 + (CASE WHEN (`hp` > 105) THEN (`hp` - 105) WHEN NOT (`hp` > 105) THEN 0 END * -017198)) + (CASE WHEN (`hp` > 175) THEN (`hp` - 175) WHEN NOT (`hp` > 175) THEN 0 END * -2.746445)))) AS .pred_0
      <SQL> 1 - `.pred_0` AS .pred_1

# sql works for randomForest classification

    Code
      orbital_sql(obj, con)
    Output
      <SQL> ((CASE
      WHEN (`hp` <= 136.5) THEN (CASE
      WHEN (`disp` <= 153.35) THEN 0
      ELSE CASE WHEN (`disp` <= 163.8) THEN 1 ELSE 0 END
      END)
      ELSE 1
      END) + (CASE WHEN (`hp` <= 136.5) THEN 0 ELSE 1 END)) + (CASE WHEN (`mpg` <= 17.7) THEN 1 ELSE 0 END) AS 0
      <SQL> ((CASE
      WHEN (`hp` <= 136.5) THEN (CASE
      WHEN (`disp` <= 153.35) THEN 1
      ELSE CASE WHEN (`disp` <= 163.8) THEN 0 ELSE 1 END
      END)
      ELSE 0
      END) + (CASE WHEN (`hp` <= 136.5) THEN 1 ELSE 0 END)) + (CASE WHEN (`mpg` <= 17.7) THEN 0 ELSE 1 END) AS 1
      <SQL> CASE WHEN (`0` >= `1`) THEN '0' ELSE '1' END AS .pred_class
      <SQL> (`0`) / 3 AS .pred_0
      <SQL> (`1`) / 3 AS .pred_1

# sql works for ranger classification

    Code
      orbital_sql(obj, con)
    Output
      <SQL> ((CASE
      WHEN (`disp` <= 266.9) THEN (CASE WHEN (`mpg` <= 21.2) THEN 0.5 ELSE 0 END)
      ELSE 1
      END) + (CASE
      WHEN (`mpg` <= 21.2) THEN (CASE WHEN (`disp` <= 221.7) THEN 0.6666667 ELSE 1 END)
      ELSE CASE WHEN (`mpg` <= 25.2) THEN 0 ELSE 0.5 END
      END)) + (CASE
      WHEN (`mpg` <= 21.2) THEN (CASE WHEN (`disp` <= 221.7) THEN 0.5714286 ELSE 1 END)
      ELSE 0.1
      END) AS 0
      <SQL> ((CASE
      WHEN (`disp` <= 266.9) THEN (CASE WHEN (`mpg` <= 21.2) THEN 0.5 ELSE 1 END)
      ELSE 0
      END) + (CASE
      WHEN (`mpg` <= 21.2) THEN (CASE WHEN (`disp` <= 221.7) THEN 0.3333333 ELSE 0 END)
      ELSE CASE WHEN (`mpg` <= 25.2) THEN 1 ELSE 0.5 END
      END)) + (CASE
      WHEN (`mpg` <= 21.2) THEN (CASE WHEN (`disp` <= 221.7) THEN 0.4285714 ELSE 0 END)
      ELSE 0.9
      END) AS 1
      <SQL> (`0`) / 3 AS .pred_0
      <SQL> (`1`) / 3 AS .pred_1
      <SQL> CASE WHEN (`0` >= `1`) THEN '0' ELSE '1' END AS .pred_class

