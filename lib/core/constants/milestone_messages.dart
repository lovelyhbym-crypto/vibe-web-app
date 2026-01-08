class MilestoneMessages {
  static const Map<int, List<String>> korean = {
    20: [
      "오, 이게 되네? 가보자고! {goalName} 20% 입성",
      "유혹 참기 폼 미쳤다; 벌써 20%라고?",
      "중요한 건 꺾이지 않는 저축심. {goalName} 실루엣 포착!",
      "지름신: '아니 이걸 참네?' (당황해서 뒷걸음질 중)",
      "작은 저축이 모여 거대한 {goalName}이(가) 되는 첫 번째 관문 통과!",
    ],
    50: [
      "절반의 승리. {goalName}이 현실로 다가오는 중.",
      "가슴이 웅장해진다... {goalName} 고지 절반 점령!",
      "여기서 멈추면 바보? '오히려 좋아' 정신으로 직진합니다.",
      "인내심 MBTI 검사 결과 : {goalName}에 미친 'P.R.O' 확정.",
      "고생 끝에 {goalName} 온다. 이제 남은 절반도 식은 죽 먹기죠?",
    ],
    80: [
      "언박싱 냄새 안 나요? 80% 돌파, 풀액셀 밟으세요!",
      "눈앞에 {goalName}이(가) 아른거려요. 마지막 스퍼트, 가시죠!",
      "이게 되네? {goalName} 영접 5분 전(은 아니지만 아무튼 곧임).",
      "카드값: '나 좀 써줘...' / 당신: '어림없지! {goalName} 기다려라~'",
      "이제 손만 뻗으면 {goalName}입니다. 당신의 인내가 빛을 발하네요.",
    ],
    100: [
      "완-벽. 지금 당장 {goalName} 데려오세요!",
      "인내가 결실을 맺었습니다. {goalName}은(는) 이제 온전히 당신 것!",
      "{goalName} 쟁취 완료. 오늘부터 '갓생' 메달 수여합니다.",
      "유혹들 다 비켜! {goalName} 주인이 나가신다 ~",
      "기다림 끝에 온 보상은 더 달콤하죠. {goalName}와(과) 행복한 시간 보내세요!",
    ],
  };

  static const Map<int, List<String>> english = {
    20: [
      "Wow, it's happening! Let's go! {goalName} 20% reached!",
      "Resisting temptation looks good on you; 20% already?",
      "The important thing is an unbreakable saving spirit. {goalName} silhouette spotted!",
      "Impulse buying: 'Wait, you're resisting?' (Backing away confused)",
      "Passed the first gate where small savings become a giant {goalName}!",
    ],
    50: [
      "Halfway victory. {goalName} is becoming real.",
      "My heart is swelling... {goalName} half conquered!",
      "Stopping here would be foolish. Going straight with 'Even better' spirit.",
      "Patience MBTI result: Certified 'P.R.O' crazy about {goalName}.",
      "{goalName} comes after hardship. The remaining half is a piece of cake, right?",
    ],
    80: [
      "Can't you smell the unboxing? 80% passed, step on the gas!",
      "{goalName} is flickering before my eyes. Last spurt, let's go!",
      "It's actually happening? 5 minutes until meeting {goalName} (not really, but soon).",
      "Credit Card: 'Use me...' / You: 'No way! {goalName} wait for me~'",
      "Now {goalName} is within reach. Your patience is shining.",
    ],
    100: [
      "Per-fect. Go get {goalName} right now!",
      "Patience has borne fruit. {goalName} is now fully yours!",
      "{goalName} acquired. Awarding you the 'God-Life' medal starting today.",
      "Temptations move aside! The owner of {goalName} is coming through ~",
      "The reward after waiting is sweeter. Have a happy time with {goalName}!",
    ],
  };

  static List<String> getMessages(int percent, String languageCode) {
    if (languageCode == 'ko') {
      return korean[percent] ?? [];
    } else {
      return english[percent] ?? [];
    }
  }
}
