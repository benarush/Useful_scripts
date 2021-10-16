from random import random
import matplotlib.pyplot as plt

s = 0.95
NUMBER_OF_TESTS = 200
NUMBER_OF_SAMPLES_PER_TEST = 10

probabilities_by_count = [0 for n in range(0, NUMBER_OF_SAMPLES_PER_TEST)]

#  count all tests results
for tests in range(0, NUMBER_OF_TESTS):  # NUMBER_OF_TESTS * NUMBER_OF_SMAPLES_PER_TEST
    test_result = 0
    for x in range(0, NUMBER_OF_SAMPLES_PER_TEST - 1):
        test_result += 1 if random() < s else 0
    probabilities_by_count[test_result] += 1

#  convert counts to percentages
probability_percentages = [value / NUMBER_OF_TESTS for value in probabilities_by_count]
#  made x titles
titles = [f"{n +1}/{len(probabilities_by_count)}" for n in range(0, len(probabilities_by_count))]


plt.bar(titles, probability_percentages)
plt.title('successes Vs chances')
plt.xlabel(f'times of success, S={s}')
plt.ylabel('percentage %')
plt.show()
